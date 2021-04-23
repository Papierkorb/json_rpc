require "http/web_socket"

require "../spec_helper"

describe "Websocket client end-to-end test" do
  it "works" do
    server_request = nil

    # Set up websockets on a blocking bidirectional IO
    client_ws, server_ws = mock_websockets

    server_ws.on_message do |m|
      server_request = m
      req = JsonRpc::Request.from_json m
      server_ws.send req.respond(m).to_json
    end

    spawn { server_ws.run }

    client = JsonRpc::WebSocketClient.new(client_ws, "/json-rpc")
    client_response = client.call(String, "C2S", ["Konnichiwa"])

    server_request.should_not eq nil
    server_request.should eq client_response
    server_ws.close
  end
end
