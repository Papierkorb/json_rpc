module JsonRpc
  # Implements JSON-RPC over TCP.
  class TcpClient < StreamClient
    getter socket : TCPSocket

    # Creates a TCP client from *socket*.  If *run* is `true`, the client will
    # start accepting messages right away.  If you choose to pass `false`, then
    # make sure to call `#run` some time afterwards manually, even if you're
    # only calling remote methods.
    def initialize(@socket, run = true)
      super(DocumentStream.new(@socket), @socket.remote_address.to_s, run)
    end

    def inspect(io)
      io << "<TCP/" << @remote_address << ">"
    end
  end
end
