module JsonRpc
  # Client class for JSON-RPC.  See one of its sub-classes for implementations.
  #
  # The client offers a built-in flood-protection for received messages.
  # Note that these are counted towards *all* messages, and thus include
  # responses to made remote invocations from our end.
  #
  # By default, the flood-protection allows for 6000 messages per minute, or
  # about 100 messages per second.  You can change these values through
  # `#flood_time_span` and `#flood_messages`.
  abstract class Client
    # Called to send *message_data* identified by *id*.
    abstract def send_message(id, message_data : String)

    # Called to receive a message.
    abstract def recv_message(id)

    # Returns the remote address for display/logging purposes
    abstract def remote_address : String

    # If `true`, all locally invoked methods will be run in their own fiber.
    property async_call : Bool = false

    # Time span in which a max count of `#flood_messages` messages can be
    # received before triggering the flood protection.
    property flood_time_span : Time::Span = 1.minute

    # Count of max messages in `#flood_time_span`, after which the flood
    # protection is triggered.
    #
    # Set to `nil` to disable the flood-protection.
    property flood_messages : Int32? = 6000

    @flood_time_end : Time = Time.now
    @flood_count : Int32 = 0

    # Total count of messages sent.
    getter messages_sent : UInt64 = 0u64

    # Total count of messages received.
    getter messages_received : UInt64 = 0u64

    @id_counter = 0i64

    # Emitted when a notification is received
    Cute.signal notification(method : String, data : JSON::Any)

    # Emitted when the remote end has called a local method, but the handler
    # (Set through `#on_call`) raised an exception which is not a
    # `LocalCallError`.
    Cute.signal fatal_local_error(request : Request(JSON::Any), raw : String, error : Exception)

    # Emitted when the remote end sent something the implementation was not able
    # to handle.  Usually happens when receiving garbage.
    Cute.signal fatal_remote_error(raw : String?, error : Exception)

    # Emitted when an implementation noticed that its connection has been lost.
    Cute.signal connection_lost

    # Emitted when the built-in flood protection was triggered.
    Cute.signal flood_protection_triggered

    def initialize
      @running = true
    end

    # If the client is currently running, accepting messages, and hopefully also
    # still connected.
    getter? running : Bool

    # Closes the connection.
    def close
      if @running
        @running = false
        connection_lost.emit

        # Is this required?  Once the client is thrown out of all managers,
        # it should not be referenced by any root-accessible object anymore,
        # and the GC should eat it.
        notification.disconnect
        fatal_local_error.disconnect
        fatal_remote_error.disconnect
        connection_lost.disconnect
        flood_protection_triggered.disconnect
      end
    end

    # Calls a remote *method* with optional *params*, returning a *result_type*.
    #
    # Note: Right now, you have to pass `JsonRpc::Response(YourType)` for
    # *result_type*, not just `YourType` !
    #
    # ## Error behaviour
    #
    # On success the result of the invocation is returned.  If however the
    # remote signals an error through the `"error"` field (per JSON-RPC), it
    # will be re-raised locally as `RemoteCallError`.
    #
    # See `#call?` for a non-raising version.
    def call(result_type, method : String, params = nil)
      result = call?(result_type, method, params)

      raise result if result.is_a?(RemoteCallError)
      raise ResponseError.new("Null response from calling #{method}") if result.nil?
      result
    end

    # Calls a remote *method*, returning the result.  On error, a
    # `RemoteCallError` is **returned**. Otherwise, the **nilable** result is
    # returned.
    def call?(result_type, method : String, params = nil)
      response = call_impl(result_type, method, params)

      if err = response.error
        RemoteCallError.new("Failed to call #{method}", err)
      else
        response.result
      end
    end

    private def call_impl(result_type, method, params)
      request = Request(typeof(params)).new(next_id, method, params)
      _send_message(request.id, request.to_json)

      message_data = recv_message(request.id)
      raise Error.new("Failed to call #{method}") if message_data.nil?

      result_type.from_json message_data
    end

    # Handler which is called whenever a call is received from the
    # remote end.  The default implementation rejects every call immediately.
    #
    # See also `Handler#call`.
    property handler : Handler = DefaultHandler::INSTANCE

    # Sends a notification to *method* with *params* to the remote end.
    def notify(method : String, params = nil)
      request = Request(typeof(params)).new(nil, method, params)
      _send_message(nil, request.to_json)
    end

    # Sends a notification to the remote end, that is already serialized.
    # Useful to send a notification to many clients in bulk.
    #
    # Use `Request(T)#to_json` for easy construction of a message.
    def notify_raw(message : String)
      _send_message(nil, message)
    end

    # Called by `Client` implementations to invoke a local method.
    def invoke_from_remote(request : Request(JSON::Any), raw : String) : Nil
      if @async_call
        spawn{ process_local_invocation request, raw }
      else
        process_local_invocation request, raw
      end
    end

    private def process_local_invocation(request, raw)
      response = invoke_locally(request, raw)
      if response && response.id
        _send_message response.id, response.to_json
      end
    end

    # Used by `DelayedResponse` to send a response.
    def send_response(response : Response)
      _send_message response.id, response.to_json unless response.id.nil?
    end

    private def invoke_locally(request, raw)
      result = @handler.handle_rpc_call(self, request, raw)

      case result
      when Response then result
      when DelayedResponse then nil
      else request.respond(result)
      end

    rescue err : LocalCallError
      request.respond(err)

    rescue err
      fatal_local_error.emit request, raw, err
      request.respond(LocalCallError.new(-32603, "Internal Server Error"))
    end

    private def next_id
      @id_counter += 1
    end

    private def _send_message(id, message : String)
      @messages_sent += 1
      send_message id, message
    end

    # Counts an incoming message.  Must be called by implementations.
    protected def count_incoming_message : Bool
      @messages_received += 1

      flood_messages = @flood_messages
      return true if flood_messages.nil?

      now = Time.now
      if now > @flood_time_end
        # Last message was received a long time ago, reset flood protection.
        @flood_time_end = now + @flood_time_span
        @flood_count = 1
      else
        @flood_count += 1

        # Received more than the allowed count of messages in a short
        # time-frame?
        if @flood_count > flood_messages
          flood_protection_triggered.emit
          @flood_count = 0
          return false
        end
      end

      true
    end
  end
end
