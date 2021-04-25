require "./stream"

module JsonRpc
  # Implements JSON-RPC over a persistant data stream.
  class StreamClient < Client
    include Stream

    SIZE_LIMIT = 2 * 1024 * 1024 # 2MiB

    getter stream : DocumentStream

    # The remote address
    getter remote_address : String

    # Maximum request size limit.  If a client exceeds this, it will be
    # disconnected.  Defaults to `SIZE_LIMIT`
    property request_size_limit : Int32 = SIZE_LIMIT

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
      spawn { read_loop }
    end

    # Interface for `JsonRpc::Client`
    def send_message(_id, message_data)
      @stream.send_document message_data
      nil
    end

    # Runs the read-loop in the current fiber, blocking it.  See `#run`.
    def read_loop
      while @running
        read_once
      end
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

    def inspect(io)
      io << "<JSON-RPC/" << @remote_address << ">"
    end
  end
end
