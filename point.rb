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
      position <=> other.start.position
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
