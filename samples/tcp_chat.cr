require "../src/json_rpc"

# Shows how to create a fully-featured JSON-RPC/TCP application.
# First, run the server:
#  $ crystal samples/tcp_chat.cr server
#
# Second, run two or more clients:
#  $ crystal samples/tcp_chat.cr
# Or from a different computer:
#  $ crystal samples/tcp_chat.cr SERVER_HOST_IP
#
# Then just type and hit return in the clients to send messages.
TCP_PORT = 12345

# Client class.  Used by both the client and server applications!
class ChatClient
  include JsonRpc::Handler

  def initialize(socket : TCPSocket, run = true)
    @client = JsonRpc::TcpClient.new socket, run: run

    @client.handler = self

    # Allow only up to ten messages per minute.
    # Will emit a `flood_protection_triggered` if violated.
    # This will protect both the client and the server.
    @client.flood_time_span = 10.seconds
    @client.flood_messages = 10

    # Handle flooding
    @client.flood_protection_triggered.on do
      puts "!! Flood protection triggered"
      @client.close
    end
  end

  # Use signals to decouple client-specific and server-specific logic
  Cute.signal message_received(message : String)
  delegate connection_lost, to: @client

  delegate remote_address, notify_raw, notify, run, to: @client

  def handle_rpc_call(client, request, raw)
    case request.method
    when "message"
      message_received.emit request.params.not_nil!.as_s
      true # Return success
    else
      super
    end
  end
end

# The server class.
class ChatServer
  getter clients = [] of ChatClient # All currently connected clients

  def initialize
    @server = TCPServer.new("0.0.0.0", TCP_PORT)
  end

  def run
    puts "Now accepting connections!"

    while socket = @server.accept?   # Accept connections ...
      client = ChatClient.new socket # And register each new client
      puts "New connection from #{client.remote_address}"

      @clients << client
      setup_client_handlers client # Listen to its signals!
      broadcast_message "-> #{client.remote_address} joined"
    end
  end

  # Uses the `JsonRpc::Client#notify_raw` feature to send the same notification
  # in bulk to many clients.
  def broadcast_message(message)
    # First, construct the notification.  Set the id to `nil`!
    json_data = JsonRpc::Request(String).new(nil, "message", message).to_json
    @clients.each &.notify_raw(json_data)
  end

  def setup_client_handlers(client)
    client.connection_lost.on do # When the client closes the connection
      puts "Connection lost to #{client.remote_address}"
      @clients.delete client # Remove it, and announce it to the other clients
      broadcast_message "<- #{client.remote_address} left"
    end

    client.message_received.on do |message| # Relay received messages
      broadcast_message "<#{client.remote_address}> #{message}"
    end
  end
end

if ARGV.first? == "server" # Server mode
  ChatServer.new.run
else # Client mode
  socket = TCPSocket.new(ARGV.first? || "localhost", TCP_PORT)
  client = ChatClient.new socket # Use the same class - No code duplication :)

  client.connection_lost.on do # When the server exits
    puts "!! Connection lost"
    exit
  end

  client.message_received.on do |message|
    # The server sent us a message.  Show it to our user.
    puts "[#{Time.now}] #{message}"
  end

  puts "Connected!"
  while message = gets               # Wait for user input
    client.notify "message", message # And send it off to the server
  end
end
