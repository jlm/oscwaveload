# frozen_string_literal: true

# Copyright (c) 2024 John Messenger. All rights reserved.

# Decode a character
class Character
  attr_reader :wave, :start, :finish, :baud, :value

  def initialize(wave, start, finish, bitwidth:, logger: Logger.new(STDOUT))
    @wave = wave
    @start = start
    @finish = finish
    @bitwidth = bitwidth.to_f
    @logger = logger

    @baud = []
    @logger.debug("    character start: #{start}, finish: #{finish}, bitwidth: #{bitwidth} "\
      "-> #{(finish - start + 0.0) / bitwidth} bit periods")
    pos = start.to_i
    while pos < finish.to_i
      @baud << @wave.level_at(pos + bitwidth/2)
      break if @baud.length > 12

      pos += bitwidth
    end
    bitstring = @baud.map { |b| b == :low ? 'L' : 'H'}.join
    databits = @baud.reverse[-9..-2].map { |b| b == :low ? 'L' : 'H'}.join
    byte = 0
    val = 1
    @baud[1..8].each do |bit|
      byte += val if bit == :high
      val *= 2
    end
    @logger.debug("    #{bitstring} -> #{databits} -> #{format('0x%02x', byte)}")
    @value = byte
  end

  def to_s
    format('%02X', @value)
  end
end
