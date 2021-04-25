module JsonRpc
  # Handler used by `Client` to handle requests.
  module Handler
    # Called when a request has been received.
    # Implementations have to return what to respond, or can raise a
    # `LocalCallError` which is automatically turned into an error response.
    #
    # Raising any other error will be caught in `Client#invoke_locally`.
    #
    # The default implementation always responds with an unknown method error.
    def handle_rpc_call(client : JsonRpc::Client, request : JsonRpc::Request, raw : String)
      request.respond LocalCallError.new(-32601, "Unknown method")
    end
  end

  # Default handler used as initial value for `Client#handler`
  class DefaultHandler
    INSTANCE = new
    include Handler
  end
end
