# frozen_string_literal: true
require 'unitwise'
module OscWave
  class Point
    include Comparable
    attr_accessor :position, :level

    def initialize(position, level)
      @position = position
      @level = level
    end

    def <=>(other)
      case other
      when Point
        position <=> other.start.position
      when Numeric
        position <=> other
      when LevelEntry
        position <=> other.start.position
      end
    end

    def -(other)
      @position - other.position
    end

    def +(period)
      @position + period
    end

    def to_s
      "#{level}@#{position}"
    end
  end
end
