require "../spec_helper"

class WebSocketServer
  getter socket : HTTP::WebSocket
  getter responses = [] of String
  getter requests = [] of String

  def initialize(@socket)
    socket.on_message do |message|
      requests << message
      socket.send(responses.shift)
    end
  end

  def add_response(arg)
    responses << arg
  end
end

describe JsonRpc::WebSocketClient do
  describe "#call" do
    it "sends a request and receives a response" do
      client_ws, server_ws = mock_websockets

      server = WebSocketServer.new(server_ws)
      server.add_response %({"id":1, "result":"Okay"})

      spawn { server_ws.run }
      Fiber.yield

      client = JsonRpc::WebSocketClient.new client_ws, "/json-rpc"
      Fiber.yield

      result = client.call String, "foo"
      Fiber.yield

      result.should eq "Okay"

      request = server.requests.first?

      request.should eq JsonRpc::Request.new(1i64, "foo", nil).to_json

      server_ws.close
    end
  end
end
