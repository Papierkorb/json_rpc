require "../spec_helper"

describe JsonRpc::Message do
  describe "#response?" do
    context "for a request" do
      it "returns false" do
        JsonRpc::Message.from_json(%<{"id": 1, "method": "foo", "params": []}>).response?.should eq false
      end
    end

    context "for a response" do
      it "returns true" do
        JsonRpc::Message.from_json(%<{"id": 1, "result": true}>).response?.should eq true
      end
    end

    context "for a notification" do
      it "returns false" do
        JsonRpc::Message.from_json(%<{"id": null, "method": "foo", "params": []}>).response?.should eq false
      end
    end
  end
end
