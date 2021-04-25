require "./message"

module JsonRpc
  # Helpers for multiplexing streamed clients
  module Stream
    protected getter channels : Hash(IdType, Channel(String)) { {} of IdType => Channel(String) }

    # Interface for `JsonRpc::Client`
    def recv_message(id)
      channel = Channel(String).new
      channels[id] = channel
      channel.receive
    end

    # Processes *document* as if it was sent by the remote end.
    def process_document(document : String)
      return unless count_incoming_message
      if Message.from_json(document).response?
        process_response(document)
      else
        process_request(document)
      end
    rescue error
      fatal_remote_error.emit document, error
    end

    private def process_response(line)
      response = EmptyResponse.from_json line
      channel = channels.delete(response.id)

      if channel
        channel.send(line)
      else
        raise "Received response with unknown id=#{response.id.inspect}"
      end
    end

    private def process_request(line)
      request = Request.from_json line
      invoke_from_remote request, line
    end
  end
end
