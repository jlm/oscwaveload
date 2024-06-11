# frozen_string_literal: true
require 'unitwise'
module OscWave
  class Point
    attr_accessor :position, :level

    def initialize(position, level)
      @position = position
      @level = level
    end

    def -(other)
      @position - other.position
    end
  end
end
