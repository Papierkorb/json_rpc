class ProcHandler
  include JsonRpc::Handler

  def initialize(&@proc : JsonRpc::Client, JsonRpc::Request(JSON::Any), String -> JsonRpc::Response(String) | JsonRpc::DelayedResponse | String)
  end

  def handle_rpc_call(client : JsonRpc::Client, request : JsonRpc::Request(JSON::Any), raw : String)
    @proc.call client, request, raw
  end
end
