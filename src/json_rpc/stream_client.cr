module JsonRpc
  # Implements JSON-RPC over a persistant data stream.
  class StreamClient < Client
    SIZE_LIMIT = 2 * 1024 * 1024 # 2MiB

    getter stream : DocumentStream

    # The remote address
    getter remote_address : String

    # Maximum request size limit.  If a client exceeds this, it will be
    # disconnected.  Defaults to `SIZE_LIMIT`
    property request_size_limit : Int32 = SIZE_LIMIT

    @channels = {} of IdType => Channel(String)

    # Creates a streaming client from *stream*.  If *run* is `true`, the client will
    # start accepting messages right away.  If you choose to pass `false`, then
    # make sure to call `#run` some time afterwards manually, even if you're
    # only calling remote methods.
    def initialize(@stream, @remote_address, run = true)
      super()
      self.run if run
    end

    # Closes the stream.
    def close
      super
      @stream.io.close
    end

    # Starts the read-loop in a background fiber.  Make sure to only call this
    # method once, and only if you passed `false` for *run* to the constructor.
    #
    # If you did not do anything fancy, don't call this method.
    def run
      spawn{ read_loop }
    end

    # Interface for `Client`
    def send_message(_id, message_data)
      @stream.send_document message_data
      nil
    end

    # ditto
    def recv_message(id)
      channel = Channel(String).new
      @channels[id] = channel
      channel.receive
    end

    # Runs the read-loop in the current fiber, blocking it.  See `#run`.
    def read_loop
      while @running
        read_once
      end
    end

    # Processes *document* as if it was sent by the remote end.
    def process_document(document : String)
      return unless count_incoming_message
      msg = Message.from_json document

      if msg.response?
        process_response(document)
      else
        process_request(document)
      end
    rescue error
      fatal_remote_error.emit document, error
    end

    # Waits for exactly one document to arrive and processes it.
    def read_once
      doc = @stream.read_document(max_size: @request_size_limit)
      process_document doc
    rescue DocumentStream::DeviceClosedError
      close
    rescue error
      fatal_remote_error.emit doc, error
    end

    private def process_response(line)
      response = EmptyResponse.from_json line
      channel = @channels.delete(response.id)

      if channel
        channel.send(line)
      else
        raise "Received response with unknown id=#{response.id.inspect}"
      end
    end

    private def process_request(line)
      request = Request(JSON::Any).from_json line
      invoke_from_remote request, line
    end

    def inspect(io)
      io << "<JSON-RPC/" << @remote_address << ">"
    end
  end
end
