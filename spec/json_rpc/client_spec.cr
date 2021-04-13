require "../spec_helper"

private def create_client
  io = TestIo.new([] of Bytes)
  streamer = JsonRpc::DocumentStream.new(io)
  client = JsonRpc::StreamClient.new(streamer, "TEST", run: false)

  {io, client}
end

describe JsonRpc::Client do
  describe "#call" do
    it "sends a request" do
      io, subject = create_client

      spawn do
        subject.call String, "foo", "bar"
      end

      Fiber.yield
      io.sent.should eq [JsonRpc::Request(String).new(1i64, "foo", "bar").to_json, "\n"]
      subject.process_document %<{ "id": 1, "result": "bar" }>
    end

    it "increments the id after each call" do
      io, subject = create_client

      spawn do
        subject.call String, "foo", "bar"
        subject.call String, "one", "two"
      end

      Fiber.yield
      subject.process_document %<{ "id": 1, "result": "bar" }>
      Fiber.yield
      subject.process_document %<{ "id": 2, "result": "tada" }>

      io.sent.should eq [
        JsonRpc::Request(String).new(1i64, "foo", "bar").to_json, "\n",
        JsonRpc::Request(String).new(2i64, "one", "two").to_json, "\n",
      ]
    end

    it "returns the result" do
      result = nil

      io, subject = create_client
      ch = Channel(Nil).new

      spawn do
        result = subject.call String, "foo", "bar"
        ch.send nil
      end

      Fiber.yield

      io.sent.should eq [JsonRpc::Request(String).new(1i64, "foo", "bar").to_json, "\n"]
      subject.process_document %<{ "id": 1, "result": "Okay" }>
      ch.receive
      result.should eq "Okay"
    end

    it "raises on remote error" do
      result = nil
      error = nil

      _io, subject = create_client
      ch = Channel(Nil).new
      spawn do
        begin
          result = subject.call String, "foo", "bar"
        rescue e : JsonRpc::RemoteCallError
          error = e
        end
        ch.send nil
      end

      Fiber.yield
      subject.process_document %<{ "id": 1, "error": [ 123, "Oh noes" ] }>
      ch.receive
      result.should eq nil
      my_error = error
      my_error.should_not eq nil
      raise "Crystal bug?!" if my_error.nil?

      my_error.conforming?.should eq true
      my_error.code.should eq 123
      my_error.remote_message.should eq "Oh noes"
    end
  end

  describe "#close" do
    it "emits connection_lost" do
      _io, subject = create_client

      conn_lost = Cute.spy subject, connection_lost()
      subject.close

      conn_lost.size.should eq 1
    end

    it "doesn't double-close" do
      _io, subject = create_client

      conn_lost = Cute.spy subject, connection_lost()
      subject.close
      subject.close

      conn_lost.size.should eq 1
    end
  end

  describe "#notify" do
    it "sends a JSON-RPC notification" do
      io, subject = create_client

      subject.notify "foo", "bar"
      io.sent.should eq [JsonRpc::Request(String).new(nil, "foo", "bar").to_json, "\n"]
    end
  end

  describe "#notify_raw" do
    it "sends the message in verbatim" do
      io, subject = create_client
      subject.notify_raw "Whazzup?!"
      io.sent.should eq ["Whazzup?!", "\n"]
    end
  end

  describe "remote to local method call" do
    context "notification" do
      it "calls the handler but doesn't send a response" do
        io, client = create_client
        request = nil
        raw = nil

        client.handler = ProcHandler.new do |klient, req, raw_data|
          klient.should be client
          request = req
          raw = raw_data

          "Okay!"
        end

        request_str = %<{ "id": null, "method": "foo", "params": [123] }>
        client.process_document request_str

        raw.should eq request_str

        my_request = request
        my_request.should_not eq nil
        raise "Crystal bug" if my_request.nil?

        my_request.method.should eq "foo"
        my_request.params.should eq JSON::Any.new([JSON::Any.new(123i64)])
        my_request.id.should eq nil

        io.sent.size.should eq 0
      end
    end

    context "normal invocation" do
      it "calls the handler and sends the result" do
        io, client = create_client
        request = nil
        raw = nil

        client.handler = ProcHandler.new do |klient, req, raw_data|
          klient.should be client
          request = req
          raw = raw_data

          "Okay!"
        end

        request_str = %<{ "id": 1, "method": "foo", "params": [123] }>
        client.process_document request_str

        raw.should eq request_str

        my_request = request
        my_request.should_not eq nil
        raise "Crystal bug" if my_request.nil?

        my_request.method.should eq "foo"
        my_request.params.should eq JSON::Any.new([JSON::Any.new(123i64)])
        my_request.id.should eq 1i64

        io.sent.should eq [JsonRpc::Response.new(1i64, "Okay!", nil).to_json, "\n"]
      end

      it "calls the handler and sends the custom result" do
        io, client = create_client
        client.handler = ProcHandler.new do |_klient, _req, _raw_data|
          JsonRpc::Response.new(1i64, "Okay!", nil)
        end

        request_str = %<{ "id": 1, "method": "foo", "params": [123] }>
        client.process_document request_str

        io.sent.should eq [JsonRpc::Response.new(1i64, "Okay!", nil).to_json, "\n"]
      end

      it "calls the handler and sends an error" do
        io, client = create_client
        client.handler = ProcHandler.new do |_klient, _req, _raw_data|
          raise JsonRpc::LocalCallError.new("Private", 123, "Public", 456i64)
        end

        request_str = %<{ "id": 1, "method": "foo", "params": [123] }>
        client.process_document request_str

        io.sent.should eq [JsonRpc::Response.new(1i64, nil, JSON::Any.new [JSON::Any.new(123i64), JSON::Any.new("Public"), JSON::Any.new(456i64)]).to_json, "\n"]
      end

      it "handles a DelayedResponse" do
        io, client = create_client
        waiter = Channel(Nil).new

        client.handler = ProcHandler.new do |klient, req, _raw_data|
          delayed = req.respond_later(klient)

          spawn do
            waiter.receive
            delayed.respond "Okay!"
          end

          delayed
        end

        request_str = %<{ "id": 1, "method": "foo", "params": [123] }>
        client.process_document request_str

        io.sent.empty?.should eq true
        waiter.send nil

        io.sent.should eq [JsonRpc::Response.new(1i64, "Okay!", nil).to_json, "\n"]
      end
    end
  end

  describe "flood protection" do
    it "emits when triggered" do
      _io, subject = create_client
      flood_spy = Cute.spy subject, flood_protection_triggered()

      subject.flood_messages = 9
      10.times { subject.process_document %<{ "id": null, "method": "foo", "params": [] }> }
      flood_spy.size.should eq 1
    end

    it "does nothing if not triggered" do
      _io, subject = create_client
      flood_spy = Cute.spy subject, flood_protection_triggered()

      subject.flood_messages = 9
      9.times { subject.process_document %<{ "id": null, "method": "foo", "params": [] }> }
      flood_spy.size.should eq 0
    end
  end
end
