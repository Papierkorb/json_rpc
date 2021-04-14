class ProcHandler
  include JsonRpc::Handler

  def initialize(&@proc : JsonRpc::Client, JsonRpc::Request, String -> JsonRpc::Response | JsonRpc::DelayedResponse | String)
  end

  def handle_rpc_call(client : JsonRpc::Client, request : JsonRpc::Request, raw : String)
    @proc.call client, request, raw
  end
end
