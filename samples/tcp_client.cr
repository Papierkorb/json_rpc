require "../src/json_rpc"

# Shows how to create a JSON-RPC/TCP client.
# Works with the `tcp_server.cr` sample code.
#
# Run it:
#  $ crystal samples/tcp_client.cr

# Connect to the remote server
socket = TCPSocket.new("localhost", 1234)
client = JsonRpc::TcpClient.new socket # Turn it into a JSON-RPC connection

puts "Calling ping method..."
result = client.call String, "ping", [Time.now]
puts "Result: #{result.inspect}"
