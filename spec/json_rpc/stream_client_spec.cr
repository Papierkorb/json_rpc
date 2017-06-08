require "../spec_helper"

private def create_client(inputs = [] of String, run = false)
  io = TestIo.new(inputs)
  stream = JsonRpc::DocumentStream.new(io)
  client = JsonRpc::StreamClient.new(stream, "TEST", run)

  client.fatal_remote_error.on do |raw, error|
    pp raw, error
    abort "Unexpected fatal_remote_error"
  end

  client
end

private class BrokenStream < JsonRpc::DocumentStream
  def initialize
    super TestIo.new([] of String)
  end

  def read_document(max_size)
    raise "Stream is broken"
  end
end

describe JsonRpc::StreamClient do
  describe "#send_message" do
    it "sends a message out" do
      client = create_client
      client.send_message 123, "FooBar"
      client.stream.io.as(TestIo).sent.should eq [ "FooBar", "\n" ]
    end
  end

  describe "#recv_message" do
    it "receives a message asynchronously" do
      inputs = [ %<{"id": 1, "result": "One"}>, %<{"id": 2, "result": "Two"}> ]
      client = create_client(inputs)

      client.fatal_remote_error.on do |error|
        pp error
        abort "Unexpected fatal_remote_error"
      end

      spawn{ client.read_once }
      client.recv_message(1i64).should eq inputs[0]

      spawn{ client.read_once }
      client.recv_message(2i64).should eq inputs[1]
    end
  end

  describe "#read_once" do
    it "handles an incoming response" do
      client = create_client([ %<{"id": 1, "result": "One"}> ])

      spawn{ client.read_once }
      client.recv_message(1i64).should eq %<{"id": 1, "result": "One"}>
    end

    it "handles an incoming invocation" do
      client = create_client([ %<{"id": 2, "method": "foo", "params": "yada"}> ])
      raw = nil

      client.handler = ProcHandler.new do |klient, _, raw_data|
        klient.should be client
        raw = raw_data

        "Okay!"
      end

      client.read_once
      raw.should eq %<{"id": 2, "method": "foo", "params": "yada"}>
    end

    context "if processing fails" do
      it "emits a fatal_remote_error" do
        client = JsonRpc::StreamClient.new(BrokenStream.new, "Test", run: false)
        error_spy = Cute.spy client, fatal_remote_error(raw : String?, error : Exception)
        client.read_once

        error_spy.size.should eq 1
        error_spy[0].first.should eq nil
        error_spy[0].last.message.should eq "Stream is broken"
      end
    end

    context "on unexpected response" do
      it "emits a fatal_remote_error" do
        client = create_client([ %<{"id": 1, "result": "One"}> ])

        client.fatal_remote_error.disconnect
        error_spy = Cute.spy client, fatal_remote_error(raw : String?, error : Exception)
        client.read_once

        error_spy.size.should eq 1
        error_spy[0].first.should eq %<{"id": 1, "result": "One"}>
        error_spy[0].last.message.should eq "Received response with unknown id=1"
      end
    end
  end
end
