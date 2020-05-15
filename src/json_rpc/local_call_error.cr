module JsonRpc
  # Raised by a `Handler` to send a custom error response to the remote client.
  #
  # Instead of raising this error, you can also use `Request#error` to craft an
  # error response.
  class LocalCallError < Error
    getter object : JSON::Any

    def initialize(code : Int32, public_message : String, data = nil)
      super public_message
      @object = LocalCallError.error_object code, public_message, data
    end

    def initialize(message, code : Int32, public_message : String, data = nil)
      super message
      @object = LocalCallError.error_object code, public_message, data
    end

    def initialize(message, public_message : String, data = nil)
      super message
      @object = LocalCallError.error_object -32600, public_message, data
    end

    def initialize(public_message : String, data = nil)
      super public_message
      @object = LocalCallError.error_object -32600, public_message, data
    end

    def initialize(message, @object)
      super message
      @object = object
    end

    def self.error_object(code : Int32, public_message : String, data = nil)
      if data.nil?
        ary = [ JSON::Any.new(code.to_i64), JSON::Any.new(public_message) ]
      else
        ary = [ JSON::Any.new(code.to_i64), JSON::Any.new(public_message), JSON::Any.new(data) ]
      end

      JSON::Any.new(ary)
    end
  end
end
