require "../spec_helper"

TCP_PORT = 13888

describe "TCP end-to-end test" do
  it "works" do
    client_to_server = nil
    server_to_client = nil
    client_response = nil
    server_response = nil
    waiter = Channel(Nil).new

    spawn do # Server
      tcp_server = TCPServer.new("localhost", TCP_PORT)
      tcp_socket = tcp_server.accept
      tcp_server.close

      client = JsonRpc::TcpClient.new(tcp_socket)
      client.handler = ProcHandler.new do |_klient, _request, raw|
        client_to_server = raw
      end

      server_response = client.call(JsonRpc::Response(String), "S2C", ["Hola"])
      waiter.send nil
    end

    spawn do # Client
      tcp_socket = TCPSocket.new("localhost", TCP_PORT)
      client = JsonRpc::TcpClient.new(tcp_socket)
      client.handler = ProcHandler.new do |_klient, _request, raw|
        server_to_client = raw
      end

      client_response = client.call(JsonRpc::Response(String), "C2S", ["Hola"])
      waiter.send nil
    end

    # Wait ...
    2.times { waiter.receive }

    client_to_server.should_not eq nil
    server_to_client.should_not eq nil

    client_response.should eq client_to_server
    server_response.should eq server_to_client
  end
end
