require "../spec_helper"

private class HttpClientMock < HTTP::Client
  getter requests = [] of HTTP::Request
  getter responses = [] of HTTP::Client::Response

  def initialize
    super "does.not.exist", 0
  end

  def add_response(*args)
    @responses << HTTP::Client::Response.new(*args)
  end

  def exec(request)
    @requests << request
    @responses.shift
  end
end

describe JsonRpc::HttpClient do
  describe "#call" do
    it "sends a request and receives a response" do
      mock = HttpClientMock.new
      client = JsonRpc::HttpClient.new mock, "/json-rpc"

      mock.add_response 200, %<{"id":1, "result":"Okay"}>
      result = client.call String, "foo"
      result.should eq "Okay"

      request = mock.requests.shift
      request.method.should eq "POST"
      request.path.should eq "/json-rpc"
      request.body.try(&.gets_to_end).should eq JsonRpc::Request(String).new(1i64, "foo", nil).to_json
    end

    context "on non-200 response code" do
      it "raises a ConnectionError" do
        mock = HttpClientMock.new
        client = JsonRpc::HttpClient.new mock

        mock.add_response 404, %<{"id":1, "result":"Okay"}>

        expect_raises(JsonRpc::ConnectionError) do
          client.call String, "foo"
        end
      end
    end
  end
end
