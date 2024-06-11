# frozen_string_literal: true

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
  end

  # @param [Point] start the starting Point (level and position)
  # @param [Integer] period the number of periods for which the wave remains at this level
  def initialize(start, period)
    @start = start
    @period = period
  end

  def <=>(other)
    @period <=> other.period
  end
end
