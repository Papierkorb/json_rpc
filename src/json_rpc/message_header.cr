module JsonRpc
  # Shared properties between `JsonRpc::Request(T)` and `JsonRpc::Response(T)`
  module MessageHeader
    # Would not be standard conform, but oh well
    getter jsonrpc : String? = "2.0"

    @[JSON::Field(emit_null: true)]
    getter id : IdType?
  end
end
