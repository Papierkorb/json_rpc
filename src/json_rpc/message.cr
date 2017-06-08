module JsonRpc
  # Used by `Client` implementations to guess if the received message is a
  # request or a response.
  class Message
    JSON.mapping({
      id: {
        type: IdType,
        nilable: true,
      },
      method: {
        type: String,
        nilable: true,
      },
    })

    def response?
      @method.nil?
    end
  end
end
