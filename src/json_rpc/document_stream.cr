module JsonRpc
  # Streams JSON documents from and into an `IO` stream.
  #
  # Uses a new-line ("\n") when sending.  Doesn't require it when receiving.
  class DocumentStream
    # Maximum document size (1 MiB)
    DEFAULT_MAX_SIZE = 1024 ** 2

    # Raised when the device was closed
    class DeviceClosedError < Error
    end

    # Raised when the document exceeds the maximum size
    class DocumentTooLarge < Error
    end

    # Raised when the document is severly malformed
    class DocumentMalformed < Error
    end

    # Size of the read buffer
    BUFFER_SIZE = 1024

    # Backing `IO` stream
    getter io : IO

    # Constructs a reader with backing device *io*
    def initialize(@io : IO)
      @buffer = Bytes.new(BUFFER_SIZE)
      @buffer_size = 0
    end

    # Reads a single document from the stream.
    #
    # A document begins with a opening brace, and ends with a balancing closing
    # one.
    #
    # Note: The result may not be valid JSON.  The algorithm only tries to find
    # the end of a valid JSON document: If it's not valid, the result may be
    # neither.
    def read_document(max_size : Int = DEFAULT_MAX_SIZE) : String
      String.build do |builder|
        buffer = @buffer  # Quick access to @buffer
        braces = 0        # Track brace "depth"
        in_string = false # Are we in a string?
        doc_size = 0      # Track document size
        accept = false    # If the document was read completely
        next_offset = 0

        while accept == false
          fill_buffer if @buffer_size < 1

          offset = 0
          pos = next_offset # Iterate over the buffer.  We want to be able to easily skip bytes.
          next_offset = 0

          while pos < @buffer_size
            case buffer[pos]
            # Count brace.  Doesn't differentiate between curly and square ones.
            when '{'.ord, '['.ord
              braces += 1 unless in_string
            when '}'.ord, ']'.ord
              braces -= 1 unless in_string

              # Happens if the document reads akin to "some garbage }"
              raise DocumentMalformed.new("Closing brace without opening") if braces < 0

              if braces == 0
                accept = true
                pos += 1
                break
              end
            when '\\'.ord # When in string, skip on backslash.
              if in_string
                if pos + 1 >= @buffer_size
                  next_offset = 1 # Skip first byte in next chunk
                else
                  pos += 1 # Skip next byte in this chunk
                end
              end
            when '"'.ord # Don't count braces in strings!
              in_string = !in_string
            when ' ', '\r', '\n', '\t', '\v'
              offset += 1 if braces == 0 # Ignore whitespace
            else
              raise DocumentMalformed.new("Leading garbage bytes") if braces == 0
            end

            pos += 1
          end

          count = pos - offset
          doc_size += count # Document size attack check
          raise DocumentTooLarge.new("Max size of #{max_size} exceeded") if max_size && doc_size > max_size

          builder.write buffer[offset, count] # Keep this part
          buffer.move_from(buffer + pos) # And remove it from the buffer
          @buffer_size -= pos
        end
      end
    end

    # Sends *document*, making sure a new-line is followed by it.
    def send_document(document : String)
      @io.puts document
    end

    # Reads data from the backing IO to fill the read buffer.
    private def fill_buffer
      buf = @buffer + @buffer_size
      return 0 if buf.size == 0 # Is the buffer already full?

      count = @io.read(buf)
      raise DeviceClosedError.new("Backing IO was closed") if count < 1

      @buffer_size += count
    end
  end
end
