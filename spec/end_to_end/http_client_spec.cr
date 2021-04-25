require "../spec_helper"
require "http/server"

HTTP_PORT = 13999

describe "HTTP client end-to-end test" do
  it "works" do
    client_response = nil
    server_request = nil
    waiter = Channel(Nil).new
    server = HTTP::Server.new do |ctx|
      raw = ctx.request.body.not_nil!.gets_to_end
      server_request = raw

      req = JsonRpc::Request.from_json raw
      ctx.response.print req.respond(raw).to_json
    end

    spawn do # Server
      server.bind_tcp HTTP_PORT
      server.listen
    end

    spawn do # Client
      http_client = HTTP::Client.new("localhost", HTTP_PORT)

      client = JsonRpc::HttpClient.new(http_client)
      client_response = client.call(String, "C2S", ["Konnichiwa"])
      waiter.send nil
    end

    # Wait ...
    waiter.receive

    server_request.should_not eq nil
    server_request.should eq client_response
    server.not_nil!.close
  end
end
