require "../src/json_rpc"

# Shows how to create a JSON-RPC/TCP server.
# Works with the `tcp_client.cr` sample code.
#
# Run it:
#  $ crystal samples/tcp_server.cr

# Create a RPC handler
class MyHandler
  include JsonRpc::Handler

  # Will be called for all incoming invocation requests
  def handle_rpc_call(client : JsonRpc::Client, request : JsonRpc::Request(JSON::Any), raw : String)
    puts "Request from #{client.inspect} to #{request.method.inspect} using #{request.params.inspect}"

    case request.method        # Handle it
    when "ping"                # Implement a ping method ..
      request.respond("Pong!") # .. which responds with a pong
    else                       # Unknown method?
      super                    # Respond with unknown method error
    end
  end
end

# Create a TCPServer like normal
server = TCPServer.new("localhost", 1234)

puts "Now accepting connections!"
while socket = server.accept? # Accept loop
  # Make it a JSON-RPC client!
  client = JsonRpc::TcpClient.new socket

  puts "New connection from #{client.inspect}"
  client.handler = MyHandler.new
end
