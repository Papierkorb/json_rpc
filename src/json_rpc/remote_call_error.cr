module JsonRpc
  # Raised when the remote end signaled an invocation error
  class RemoteCallError < Error
    # The error object.  See `#conforming?`
    getter object : JSON::Any

    def initialize(message, @object)
      super message
    end

    # Returns `true` if the `#object` format conforms to the JSON-RPC
    # specification.
    def conforming? : Bool
      if ary = @object.as_a?
        (
          ary.size >= 2 &&
          ary[0].raw.is_a?(Int64) &&
          ary[1].raw.is_a?(String)
        )
      else
        false
      end
    end

    # The JSON-RPC error code
    def code : Int
      @object[0].as_i
    end

    # The JSON-RPC error message
    def remote_message : String
      @object[1].to_s
    end

    # The JSON-RPC error data.  This is optional.
    def data : JSON::Any?
      return nil if @object.size < 3
      @object[2]
    end
  end
end
