# frozen_string_literal: true

# Copyright (c) 2024 John Messenger. All rights reserved.

require_relative 'point'

class LevelEntry
  include Comparable
  attr_reader :start, :period

  class Level
    LOW = :low
    HIGH = :high

    def initialize(level)
      case level
      when Integer
        @level = [LOW, HIGH][level]
      when TrueClass, FalseClass
        @level = level ? HIGH : LOW
      when Symbol
        if [LOW, HIGH].include? level
          @level = level
        else
          raise ArgumentError, "Invalid level from symbol: #{level.inspect}"
        end
      else
        raise ArgumentError, "Invalid level: #{level.inspect}"
      end
    end

    def to_s
      @level.to_s
    end

    def to_sym
      @level
    end

    def to_i
      [LOW, HIGH].index(@level)
    end

    def invert
      if @level == LOW
        HIGH
      elsif @level == HIGH
        LOW
      else
        raise(ValueError, "invert found bad value @level==#{@level}")
      end
    end
  end

  # @param [Point] start the starting Point (level and position)
  # @param [Integer] period the number of periods for which the wave remains at this level
  def initialize(start, period)
    @start = start
    @period = period
  end

  def <=>(other)
    start <=> other
  end

  def to_s
    "#{@start}(#{@period})"
  end

  def to_i
    start.position
  end

  def -(other)
    @start - other.start
  end

  def end
    OscWave::Point.new(@start + @period, !@start.level )
  end
end
