module JsonRpc
  # Encapsulates a JSON-RPC invocation response.  See `Request#respond` to
  # create a response conveniently.
  #
  # If you're looking to receive a response with no result, see `EmptyResponse`.
  class Response(T)
    JSON.mapping({
      jsonrpc: {
        type: String,
        default: "2.0",
        nilable: true, # Would not be standard conform, but oh well
      },
      id: {
        type: IdType,
        nilable: true,
        emit_null: true,
      },
      result: {
        type: T,
        nilable: true,
        emit_null: false,
      },
      error: {
        type: JSON::Any,
        nilable: true,
        emit_null: false,
      },
    })

    def initialize(@id, @result, @error)
      @jsonrpc = "2.0"
    end
  end

  # Encapsulates an *empty* JSON-RPC invocation response.
  class EmptyResponse
    JSON.mapping({
      jsonrpc: {
        type: String,
        default: "2.0",
        nilable: true, # Would not be standard conform, but oh well
      },
      id: {
        type: IdType,
        nilable: true,
        emit_null: true,
      },
      error: {
        type: JSON::Any,
        nilable: true,
        emit_null: false,
      },
    })

    def initialize(@id, @error = nil)
      @jsonrpc = "2.0"
    end
  end
end
