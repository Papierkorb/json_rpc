require "spec"
require "cute/spec"

require "../src/json_rpc"
require "./test_io"
require "./proc_handler"

# Set up websockets on a blocking bidirectional IO
def mock_websockets
  io_l, io_r = IO::Stapled.pipe
  ({HTTP::WebSocket.new(io_l), HTTP::WebSocket.new(io_r)})
end
