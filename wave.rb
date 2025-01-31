# frozen_string_literal: true

# Copyright (c) 2024 John Messenger. All rights reserved.

require 'unitwise'
module OscWave

  class Wave
    attr_accessor :timebase, :rate, :amplitude, :amplres, :data_unit, :data_points, :data, :pos, :levels

    module Wave
      class Indeterminate < RuntimeError
      end

      class PositionOutOfRange < RuntimeError
      end
    end

    def initialize(wave, logger: Logger.new(STDERR))
      @logger = logger
      @data = []
      @others = []
      @pos = 0
      if wave.is_a? String
        begin
          stream = File.open(wave, 'r:bom|utf-8')
        end
      elsif wave.is_a? IO
        stream = wave
      else
        raise "unrecognised content type: #{wave.class}"
      end
      logger.debug "reading data from: #{stream.to_path}"

      stream.each_line do |line|
        line.chomp!
        if line.match?(/^[A-Z]/)
          k, v = line.split(':')
          case k
          when 'Time Base'
            @timebase = parse_float_unit(v)
          when 'Sampling Rate'
            @rate = v
          when 'Amplitude'
            @amplitude = parse_float_unit(v)
          when 'Amplitude resolution'
            @amplres = parse_float_unit(v)
          when 'Data Uint'
            @data_unit = v.match(/(.)v/) ? "#{$1}V" : v
          when 'Data points'
            @data_points = v.to_i
          else
            @others << [k, v]
          end
        else
          @data << line.to_f
        end
      end

      @min = @data.min
      @max = @data.max
      @midpoint = (@min + @max) / 2
      @high_t = (@max + @midpoint) / 2
      @low_t = (@min + @midpoint) / 2
      logger.debug("midpoint: #{@midpoint}; high threshold: #{@high_t}; low threshold: #{@low_t}")
    end

    def sample_period
      rate = @rate[0..-5]
      rate = multiplier(rate.to_f, rate[-1])
      1.0 / rate
    end

    def next_low
      ((@pos + 1)..(@data_points - 1)).each do |pos|
        if @data[pos] < @low_t
          return @pos = pos
        end
      end
      nil
    end

    def next_high
      ((@pos + 1)..(@data_points - 1)).each do |pos|
        if @data[pos] > @high_t
          return @pos = pos
        end
      end
      nil
    end

    def next_edge
      cv = @data[@pos]
      if cv > @high_t
        return next_low
      elsif cv < @low_t
        return next_high
      end

      nil
    end

    def level_at(pos)
      if @data[pos] < @low_t
        LevelEntry::Level::LOW
      elsif @data[pos] > @high_t
        LevelEntry::Level::HIGH
      else
        raise Wave::Indeterminate, "Indeterminate level not outside range #{@low_t} to #{@high_t}"
      end
    end

    def current_level
      level_at(@pos)
    end

    def extract_levels
      @pos = 0
      @levels = []
      while @pos < data_points do
        p1 = Point.new(@pos, current_level)
        break unless next_edge

        p2 = Point.new(@pos, current_level)
        period = p2 - p1
        @logger.debug "#{p1} for #{period} periods, #{format_time((sample_period * period).round(4))}"
        @levels << LevelEntry.new(p1, period)
      end

    end

    def format_time(time, round: 4)
      units = %w[s ms µs ns ps]
      negative = time < 0.0
      time = -time if negative

      units.each do |unit|
        return "#{negative ? '-' : ''}#{time.round(round).to_s} #{unit}" if time > 1.0

        time *= 1000.0
      end
    end

    def multiplier(num, mul)
      table = {
        'k': 1000,
        'M': 1000 * 1000,
        'G': 1000 * 1000 * 1000,
        'T': 1000 * 1000 * 1000 * 1000
      }
      multiplier = table[mul.to_sym]
      num *= multiplier if multiplier
      num
    end

    def get_position(start)
      case start
      when Numeric
        start
      when Point
        start.position
      when LevelEntry
        start.start.position
      else
        raise TypeError, 'find_pulse: start must be a position, Point or LevelEntry'
      end
    end

    # Look for a pulse in the wave data.
    # @param start Search from here
    # @param level the logic level of the sought pulse
    # @param pulse_width the [minimum,maximum] pulse width
    # @param options an array of options such as {complain: "description"}
    # @return LevelEntry of first matching pulse, or nil
    def find_pulse(start, level, pulse_width,
      options = {})
      min_width, max_width = pulse_width
      start_pos = get_position(start)
      raise Wave::PositionOutOfRange unless start_pos.between?(0, @data_points)

      @levels.each do |lent|
        return lent if lent.start.position >= start_pos &&
                       lent.start.level == level &&
                       lent.period >= min_width &&
                       lent.period <= max_width
      end
      raise "didn't find pulse: #{options[:complain]}" if options[:complain]

      nil
    end

    private

    FLOAT_REGEX = /(([1-9][0-9]*\.?[0-9]*)|(\.[0-9]+))([Ee][+-]?[0-9]+)?/

    def parse_float_unit(str)
      number = str.match(FLOAT_REGEX)[0]
      unit = str.split(FLOAT_REGEX)[-1]
      Unitwise(number, unit)
    end

  end
end
