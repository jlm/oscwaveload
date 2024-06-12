# frozen_string_literal: true
require_relative 'point'

class LevelEntry
  include Comparable
  attr_reader :start, :period

  class Level
    LOW = :low
    HIGH = :high
    LEVEL_NAMES = {
      LOW: "Low",
      HIGH: "High",
    }
    def self.to_s(level)
      LEVEL_NAMES[level.to_sym]
    end

    def self.!(level)
      level == HIGH ? LOW : HIGH
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

  def -(other)
    @start - other.start
  end

  def end
    OscWave::Point.new(@start + @period, !@start.level )
  end
end
