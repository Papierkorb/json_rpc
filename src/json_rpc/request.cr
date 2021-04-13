require "json"

require "./message_header"

module JsonRpc
  # Encapsulates a JSON-RPC request object
  struct Request(T)
    include JSON::Serializable
    include MessageHeader

    getter method : String

    getter params : T?

    def initialize(@id, @method, @params)
    end

    # Creates an error response.
    def respond(failure : LocalCallError)
      Response.new(id, nil, failure.object)
    end

    # Creates an error response.
    def error(code : Int32, message : String, data : JSON::Any? = nil)
      Response.new(id, nil, LocalCallError.error_object(code, public_message, data))
    end

    # Creates a successful response based on *result*.
    def respond(result)
      Response.new(id, result, nil)
    end

    # Returns a `DelayedResponse`, bound to *client*.
    #
    # Return the result of this method from your `Handler#handle_rpc_call`, and
    # keep a handle to it somewhere to respond later.
    def respond_later(client : Client) : DelayedResponse
      DelayedResponse.new(id, client)
    end
  end
end
