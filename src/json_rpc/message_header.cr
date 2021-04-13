require "json"

module JsonRpc
  # Shared properties between `JsonRpc::Request` and `JsonRpc::Response`
  module MessageHeader
    # Would not be standard conform, but oh well
    getter jsonrpc : String? = "2.0"

    @[JSON::Field(emit_null: true)]
    getter id : IdType?
  end
end
