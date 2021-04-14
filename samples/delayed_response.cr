require "../src/json_rpc"

# Shows how to use `JsonRpc::DelayedResponse` to respond at a later time to a
# client invocation.
#
# Works with the `tcp_client.cr` sample code.
#
# Run it:
#  $ crystal samples/delayed_response.cr

class MyHandler
  include JsonRpc::Handler

  def run_intense_computation(responder)
    spawn do
      puts "Starting intense computation"
      sleep 3.seconds
      puts "Intense computation has finished!"

      responder.respond "Okay!"
    end
  end

  # Will be called for all incoming invocation requests
  def handle_rpc_call(client : JsonRpc::Client, request : JsonRpc::Request, raw : String)
    puts "Request from #{client.inspect} to #{request.method} using #{request.params.inspect}"

    case request.method
    when "ping"
      delayed = request.respond_later client # Respond later...
      run_intense_computation delayed        # Do some asynchronous work
      delayed                                # Signal that we will respond later!
    else
      super
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
