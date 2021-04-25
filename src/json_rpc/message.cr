require "json"

module JsonRpc
  # Used by `Client` implementations to guess if the received message is a
  # request or a response.
  struct Message
    include JSON::Serializable
    getter id : IdType?
    getter method : String?

    @[JSON::Field(ignore: true)]
    getter? response : Bool { method.nil? }
  end
end
