# frozen_string_literal: true

require 'minitest/autorun'
require_relative "../level_entry"

class LevelTest < Minitest::Test
  def setup
    # Do nothing
  end

  def teardown
    # Do nothing
  end

  def test_to_i
    puts "to_i tests"
    assert_equal(0, LevelEntry::Level.new(LevelEntry::Level::LOW).to_i)
    assert_equal(1, LevelEntry::Level.new(LevelEntry::Level::HIGH).to_i)
  end

  def test_to_sym
    puts "to_a tests"
    assert_equal(:low, LevelEntry::Level.new(LevelEntry::Level::LOW).to_sym)
    assert_equal(:high, LevelEntry::Level.new(LevelEntry::Level::HIGH).to_sym)
  end

  def test_incoming_conversion
    puts 'initialisation tests'
    assert_equal(LevelEntry::Level::LOW, LevelEntry::Level.new(false).to_sym)
    assert_equal(LevelEntry::Level::HIGH, LevelEntry::Level.new(true).to_sym)
    assert_equal(LevelEntry::Level::LOW, LevelEntry::Level.new(0).to_sym)
    assert_equal(LevelEntry::Level::HIGH, LevelEntry::Level.new(1).to_sym)
    assert_equal(LevelEntry::Level::LOW, LevelEntry::Level.new(:low).to_sym)
    assert_equal(LevelEntry::Level::HIGH, LevelEntry::Level.new(:high).to_sym)
    assert_raises ArgumentError do
      LevelEntry::Level.new(:cow)
    end
  end
end
