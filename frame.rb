# frozen_string_literal: true

# Copyright (c) 2024 John Messenger. All rights reserved.

require_relative 'character'

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

  def to_s(value = false)
    if value
      @characters.map(&:to_s).join(' ')
    else
      "#{@start}/#{@finish}"
    end
  end

  def a_bit_less_than(length)
    length * 0.9
  end

  def extract_characters(train_chars:, start_bit_width:)
    @characters = []
    learned_char_length = nil
    pos = @start
    while pos < @finish
      pos = @wave.find_pulse(pos, :high, start_bit_width, { complain: 'Start of character' })
      @logger.debug("Start of character at #{pos}")
      # Once training is done, switch to looking for the next character at a predicted location, using relaxed bit-length
      if @characters.length == train_chars
        learned_char_length = average_char_length(@characters)
        start_bit_width[1] = a_bit_less_than(learned_char_length)
      end
      likely_next_char_start = learned_char_length.nil? ? pos.end : (pos.start + a_bit_less_than(learned_char_length))
      nextcharpos = @wave.find_pulse(likely_next_char_start, :high, start_bit_width, { complain: 'Start of next character' })
      @logger.info("  Character #{@characters.length}: start: #{pos}; length: #{nextcharpos - pos} "\
        "or #{@wave.format_time((nextcharpos - pos) * @wave.sample_period)}")
      @characters << Character.new(@wave, pos, nextcharpos, bitwidth: 40, logger: @logger)
      pos = nextcharpos
    end
    @characters
  end

  private
  def average_char_length(chars)
    total = 0.0
    chars.each do |char|
      total += char.finish - char.start
    end
    total / chars.length
  end


end
