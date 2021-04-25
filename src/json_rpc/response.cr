require "json"

require "./message_header"

module JsonRpc
  private abstract struct ResponseBase
    include JSON::Serializable
    include MessageHeader

    getter error : JSON::Any?

    def initialize(@id, @error)
    end
  end

  # Encapsulates a JSON-RPC invocation response.  See `Request#respond` to
  # create a response conveniently.
  struct Response < ResponseBase
    @[JSON::Field(converter: String::RawConverter)]
    getter result : String?

    def initialize(@id, result, @error)
      @result = result.try &.to_json
      super(@id, @error)
    end
  end

  # `JsonRpc::Response` with no `result` key
  struct EmptyResponse < ResponseBase
  end
end
