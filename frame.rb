# frozen_string_literal: true

# Parse a frame into characters
class Frame
  attr_reader :wave, :start, :finish, :length

  def initialize(wave, start, finish, length, logger: Logger.new(STDOUT))
    @wave = wave
    @start = start
    @finish = finish
    @length = length
    @logger = logger
  end

  def to_s
    "#{@start}/#{@finish}"
  end

  def a_bit_less_than(length)
    length * 0.9
  end

  def extract_characters(train_chars:, start_bit_width:)
    @chars = []
    learned_char_length = nil
    pos = @start
    while pos < @finish
      pos = @wave.find_pulse(pos, :high, start_bit_width, { complain: 'Start of character' })
      @logger.debug("Start of character at #{pos}")
      # Once training is done, switch to looking for the next character at a predicted location, using relaxed bit-length
      if @chars.length == train_chars
        learned_char_length = average_char_length(@chars)
        start_bit_width[1] = a_bit_less_than(learned_char_length)
      end
      likely_next_char_start = learned_char_length.nil? ? pos.end : (pos.start + a_bit_less_than(learned_char_length))
      nextcharpos = @wave.find_pulse(likely_next_char_start, :high, start_bit_width, { complain: 'Start of next character' })
      @logger.info("  Character #{@chars.length}: start: #{pos}; length: #{nextcharpos - pos} "\
        "or #{@wave.format_time((nextcharpos - pos) * @wave.sample_period)}")
      @chars << { start: pos, end: nextcharpos }
      pos = nextcharpos
    end
    @chars
  end

end
