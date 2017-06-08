require "../spec_helper"
require "http/server"

HTTP_PORT = 13999

describe "HTTP client end-to-end test" do
  it "works" do
    client_response = nil
    server_request = nil
    waiter = Channel(Nil).new

    spawn do # Server
      server = nil
      server = HTTP::Server.new("localhost", HTTP_PORT) do |ctx|
        raw = ctx.request.body.not_nil!.gets_to_end
        server_request = raw

        req = JsonRpc::Request(Array(String)).from_json raw
        ctx.response.print req.respond(raw).to_json

        server.not_nil!.close
      end

      server.not_nil!.listen
      waiter.send nil
    end

    spawn do # Client
      http_client = HTTP::Client.new("localhost", HTTP_PORT)

      client = JsonRpc::HttpClient.new(http_client)
      client_response = client.call(JsonRpc::Response(String), "C2S", [ "Konnichiwa" ])
      waiter.send nil
    end

    # Wait ...
    2.times{ waiter.receive }

    server_request.should_not eq nil
    server_request.should eq client_response
  end
end
