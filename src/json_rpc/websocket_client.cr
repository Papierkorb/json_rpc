require "http/web_socket"

require "./stream"

module JsonRpc
  # Implements JSON-RPC over WebSocket.
  class WebSocketClient < Client
    include Stream

    getter remote_address : String

    getter socket : HTTP::WebSocket

    # Creates a WebSocket client from `HTTP::WebSocket`*.
    # If *run* is `true`, the client will start accepting messages right away.
    # If you choose to pass `false`, then make sure to call `#run` some time
    # afterwards manually, even if you're only calling remote methods.
    def initialize(@socket, @remote_address, run = true)
      socket.on_message { |document| process_document(document) }
      socker.on_close { close rescue nil }
      self.run if run
    end

    # Starts the WebSocket read-loop in a background fiber.
    # Make sure to onlyicall this method once, and only if you passed `false`
    # for *run* to the constructor.
    #
    # If you did not do anything fancy, don't call this method.
    def run
      spawn { socket.run }
    end

    # Interface for `JsonRpc::Client`
    def send_message(_id, message_data : String)
      socket.send(message_data)
      nil
    end

    def close
      super()
      socket.close
    end

    def inspect(io)
      io << "<WebSocket/" << remote_address << ">"
    end
  end
end
