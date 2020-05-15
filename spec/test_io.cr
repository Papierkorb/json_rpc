class TestIo < IO

  getter sent = [] of String

  def initialize(choreography : Array(String))
    @choreography = choreography.map(&.to_slice).to_a
  end

  def initialize(@choreography : Array(Bytes))
  end

  def read(buffer : Bytes)
    current = @choreography.first?
    return 0 if current.nil?

    count = { buffer.size, current.size }.min
    buffer.copy_from current[0, count]

    if (current + count).size < 1
      @choreography.shift
    else
      @choreography[0] = current + count
    end

    count
  end

  def write(buffer : Bytes) : Nil
    @sent << String.new(buffer)
    nil
  end
end
