module JsonRpc
  # Encapsulates a JSON-RPC request object
  class Request(T)
    JSON.mapping({
      jsonrpc: {
        type:    String,
        default: "2.0",
        nilable: true, # Would not be standard conform, but oh well
      },
      id: {
        type:      IdType,
        nilable:   true,
        emit_null: true,
      },
      method: {
        type: String,
      },
      params: {
        type:    T,
        nilable: true,
      },
    })

    def initialize(@id, @method, @params)
      @jsonrpc = "2.0"
    end

    # Creates an error response.
    def respond(failure : LocalCallError)
      Response(Nil).new(@id, nil, failure.object)
    end

    # Creates an error response.
    def error(code : Int32, message : String, data : JSON::Any? = nil)
      Response(Nil).new(@id, nil, LocalCallError.error_object(code, public_message, data))
    end

    # Creates a successful response based on *result*.
    def respond(result)
      Response(typeof(result)).new(@id, result, nil)
    end

    # Returns a `DelayedResponse`, bound to *client*.
    #
    # Return the result of this method from your `Handler#handle_rpc_call`, and
    # keep a handle to it somewhere to respond later.
    def respond_later(client : Client) : DelayedResponse
      DelayedResponse.new(@id, client)
    end
  end
end
