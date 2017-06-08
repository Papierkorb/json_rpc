module JsonRpc
  # Implements JSON-RPC over HTTP transport.  Uses POST requests and doesn't
  # support notifications to be received.
  #
  # ## Authentication
  #
  # To do authentication, configure the `HTTP::Client` you pass in as needed.
  #
  # An example for HTTP Basic auth:
  # ```crystal
  #   http_client = HTTP::Client.new("some.internal.server", 1234)
  #   http_client.basic_auth("my-username", "the-password")
  #
  #   rpc_client = JsonRpc::HttpClient.new(http_client)
  #   # rpc_client will now use basic authentication for each request!
  # ```
  class HttpClient < Client
    getter http_client : HTTP::Client
    property endpoint : String

    # TODO: Multi-threading
    @buffer = {} of IdType => String

    def initialize(@http_client : HTTP::Client, @endpoint = "/")
      super()
    end

    def send_message(id, message_data)
      response = @http_client.post @endpoint, nil, message_data

      if response.status_code != 200
        raise ConnectionError.new("Unexpected HTTP code #{response.status_code}")
      end

      # Save the response for now, and return it later in #recv_message.
      @buffer[id] = response.body unless id.nil?
    end

    # Dummy implementation, this client doesn't use a persistant connection,
    # and will never receive a remotely-initiated packet.
    def recv_message(id)
      # Allow for slow, concurrent requests to work
      @buffer.delete id
    end

    def remote_address
      "#{@http_client.host}:#{@http_client.port}#{@endpoint}"
    end

    def inspect(io)
      io << "<HTTP/" << @http_client.host << ":" << @http_client.port << ">"
    end
  end
end
