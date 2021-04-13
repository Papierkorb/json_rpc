require "json"

require "./message_header"

module JsonRpc
  private abstract struct ResponseBase(T)
    include JSON::Serializable
    include MessageHeader

    getter error : JSON::Any?

    def initialize(@id, @error)
    end
  end

  # Encapsulates a JSON-RPC invocation response.  See `Request#respond` to
  # create a response conveniently.
  struct Response(T) < ResponseBase(T)
    getter result : T?

    def initialize(@id, @result, @error)
      super(@id, @error)
    end
  end

  # `JsonRpc::Response(T)` with no `result` key
  struct EmptyResponse < ResponseBase(Nil)
  end
end
