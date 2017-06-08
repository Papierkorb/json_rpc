require "../src/json_rpc"

# Shows how to communicate with a HTTP Basic-auth protected JSON-RPC resource.
# Tries to acquire the current balance of a bitcoin testnet RPC daemon.
#
# Run:
#  $ crystal samples/http_client.cr my-rpc-user my-rpc-password
#

username = ARGV[0]
password = ARGV[1]

# Set up the HTTP client
http_client = HTTP::Client.new("localhost", 18332) # Assume Bitcoin testnet!
http_client.basic_auth username, password

# Turn it into a JSON-RPC client
client = JsonRpc::HttpClient.new http_client

# Get current balance!
balance = client.call(JsonRpc::Response(Float64), "getbalance")
#          The result will be a Float64 ^^^^^^^

puts "Current balance: #{balance}"
