module JsonRpc
  # Like `Response`, but delayed in that you can send a response to a request
  # some time after your `Handler#handle_rpc_call` has returned.
  #
  # See `Request#respond_later`
  class DelayedResponse
    # The invocation id to respond to
    getter id : IdType

    # The underlying client
    getter client : Client

    def initialize(@id, @client)
    end

    # Sends an error response.
    def respond(failure : LocalCallError)
      send Response(Nil).new(@id, nil, failure.object)
    end

    # Sends an error response.
    def error(code : Int32, message : String, data : JSON::Any? = nil)
      send Response(Nil).new(@id, nil, LocalCallError.error_object(code, public_message, data))
    end

    # Sends a successful response based on *result*.
    def respond(result)
      send Response(typeof(result)).new(@id, result, nil)
    end

    # Sends a *response* to the backing `#client`.
    def send(response : Response)
      client.send_response response
    end
  end
end
