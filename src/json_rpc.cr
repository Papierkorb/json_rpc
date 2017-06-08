require "json"
require "socket"
require "http/client"

require "cute"

module JsonRpc
  alias IdType = Int64 | String | Nil

  # Base error class
  class Error < Exception
  end

  # Raised on a faulty connection
  class ConnectionError < Error
  end

  # Raised when the response type was unexpected
  class ResponseError < Error
  end
end

require "./json_rpc/*"
