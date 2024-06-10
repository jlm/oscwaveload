# frozen_string_literal: true

class LevelEntry
  include Comparable
  attr_reader :level, :period

  def initialize(level, period)
    @level = level
    @period = period
  end

  def <=>(other)
    @period <=> other.period
  end
end
