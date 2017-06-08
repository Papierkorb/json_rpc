require "../spec_helper"

private def read_doc(*inputs, max_size = 100)
  io = TestIo.new(inputs.to_a.flatten)
  JsonRpc::DocumentStream.new(io).read_document(max_size)
end

describe JsonRpc::DocumentStream do
  describe "#read_document" do
    it "accepts valid document" do
      read_doc(%<{ "hello": "you" }>).should eq %<{ "hello": "you" }>
      read_doc(%<[ "hello", "you" ]>).should eq %<[ "hello", "you" ]>
    end

    it "ignores leading whitespace" do
      read_doc(%<   { "hello": "you" }>).should eq %<{ "hello": "you" }>
      read_doc(%< \n\r { "hello": "you" }>).should eq %<{ "hello": "you" }>
      read_doc(%< \t { "hello": "you" }>).should eq %<{ "hello": "you" }>
      read_doc(%< \v { "hello": "you" }>).should eq %<{ "hello": "you" }>
    end

    it "handles chunked transfer" do
      read_doc(%<[ "hello", "you" ]>.chars.map(&.to_s).to_a).should eq %<[ "hello", "you" ]>
    end

    # Size attack protection
    context "max_size" do
      it "raises if exceeded" do
        expect_raises(JsonRpc::DocumentStream::DocumentTooLarge) do
          read_doc(%<[ "1234567890" ]>, max_size: 10)
        end
      end

      it "accepts if not exceeded" do
        read_doc(%<[ "1234" ]>, max_size: 10)
      end
    end

    it "raises on closing brace without opening first" do
      expect_raises(JsonRpc::DocumentStream::DocumentMalformed) do
        read_doc(%<}>)
      end

      expect_raises(JsonRpc::DocumentStream::DocumentMalformed) do
        read_doc(%<]>)
      end

      expect_raises(JsonRpc::DocumentStream::DocumentMalformed) do
        read_doc(%<     ]>)
      end
    end

    it "raises for leading garbage bytes" do
      expect_raises(JsonRpc::DocumentStream::DocumentMalformed) do
        read_doc(%<GET /foo.json HTTP/1.1\r\n>)
      end
    end

    it "handles strings with braces" do
      read_doc(%<[ "This works: ]" ]>).should eq %<[ "This works: ]" ]>
    end

    it "handles strings with escapes" do
      read_doc(%<[ "This works: \\"" ]>).should eq %<[ "This works: \\"" ]>
      read_doc(%<[ "This works: \\\\" ]>).should eq %<[ "This works: \\\\" ]>
    end

    it "handles strings with escapes just before a chunk ending" do
      read_doc(%<[ "This works: \\>, %<"" ]>).should eq %<[ "This works: \\"" ]>
    end

    it "allows nested objects" do
      read_doc(%<[{"foo":"bar"}, [1234]]>).should eq %<[{"foo":"bar"}, [1234]]>
    end

    it "reads multiple documents in same chunk" do
      io = TestIo.new([ %<{"foo":"bar"}{"one": 2}> ])
      stream = JsonRpc::DocumentStream.new(io)

      stream.read_document.should eq %<{"foo":"bar"}>
      stream.read_document.should eq %<{"one": 2}>
    end

    it "reads multiple documents in small chunks" do
      io = TestIo.new(%<{"foo":"bar"}{"one": 2}>.chars.map(&.to_s).to_a)
      stream = JsonRpc::DocumentStream.new(io)

      stream.read_document.should eq %<{"foo":"bar"}>
      stream.read_document.should eq %<{"one": 2}>
    end

    it "raises if device was closed before document" do
      io = TestIo.new([ ] of Bytes)
      stream = JsonRpc::DocumentStream.new(io)

      expect_raises(JsonRpc::DocumentStream::DeviceClosedError) do
        stream.read_document
      end
    end

    it "raises if device was closed mid-document" do
      io = TestIo.new([ %<{ "foo": "ba> ])
      stream = JsonRpc::DocumentStream.new(io)

      expect_raises(JsonRpc::DocumentStream::DeviceClosedError) do
        stream.read_document
      end
    end
  end
end
