# frozen_string_literal: true
require 'unitwise'
module OscWave

  class Wave
    attr_accessor :timebase, :rate, :amplitude, :amplres, :data_unit, :data_points, :data, :pos, :levels

    class Wave::Indeterminate < RuntimeError; end
    class Wave::PositionOutOfRange < RuntimeError; end

    def initialize(wave, logger: Logger.new(STDERR))
      @logger = logger
      @data = []
      @others = []
      @pos = 0
      if wave.is_a? String
        begin
          stream = File.open(wave, "r:bom|utf-8")
        end
      elsif wave.is_a? IO
        stream = wave
      else
        raise "unrecognised content type: #{wave.class}"
      end
      logger.debug "reading data from: #{stream.to_path}"

      stream.each_line do |line|
        line.chomp!
        if line.match? /^[A-Z]/
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
            @data_unit = v.match(/(.)v/) ? $1 + 'V' : v
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
      ((@pos + 1)..(@data_points-1)).each do |pos|
        if @data[pos] < @low_t
          return @pos = pos
        end
      end
      nil
    end

    def next_high
      ((@pos + 1)..(@data_points-1)).each do |pos|
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

    def current_level
      if @data[@pos] < @low_t
        LevelEntry::Level::LOW
      elsif @data[@pos] > @high_t
        LevelEntry::Level::HIGH
      else
        raise Wave::Indeterminate, "Indeterminate level not outside range #{@low_t} to #{@high_t}"
      end
    end

    def extract_levels
      @pos = 0
      @levels = []
      while @pos < data_points do
        p1 = Point.new(@pos, current_level)
        break unless next_edge
        p2 = Point.new(@pos, current_level)
        period = p2 - p1
        @logger.debug "#{p1.to_s} for #{period} periods, #{format_time((sample_period * period).round(4))}"
        @levels << LevelEntry.new(p1, period)
      end

    end

    def format_time(time, round: 4)
      units = %w[s ms µs ns ps]
      negative = time < 0.0
      time = -time if negative

      units.each do |unit|
        if time > 1.0
          return (negative ? "-" : "") + time.round(round).to_s + " " + unit
        else
          time = time * 1000.0
        end
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

    # Look for a pulse in the wave data.
    # @param [Integer] start Search from here
    # @param [LevelEntry::Level] level the logic level of the sought pulse
    # @param [Integer] min_width the minimum pulse width
    # @param [Integer] max_width the maximum pulse width
    # @param [Hash] options an array of options such as {complain: "description"}
    # @return [LevelEntry] LevelEntry of first matching pulse, or nil
    def find_pulse(start, level, min_width, max_width, options = {})
      start_pos = case
      when start.is_a?(Numeric)
        start
      when start.is_a?(Point)
        start.position
      when start.is_a?(LevelEntry)
        start.start.position
      else
        raise TypeError, "find_pulse: start must be a position, Point or LevelEntry"
      end
      raise Wave::PositionOutOfRange unless start_pos.between?(0, @data_points)
      # A high pulse consists of a rising edge followed by a falling edge.
      @levels.each do |lent|
        lsp = lent.start.position
        if lsp >= start_pos && lent.start.level == level
          @logger.debug("find_pulse: found potential matching pulse at #{lent}")
          if lent.period < min_width
            @logger.debug("find_pulse: ... but it's too narrow #{lent.period}")
            next
          elsif lent.period > max_width
            @logger.debug("find_pulse: ... but it's too wide #{lent.period}")
            next
          else
            @logger.debug("find_pulse: ... and it's just right! #{lent.period}")
            return lent
          end
        end
      end
      raise options[:complain] if options[:complain]
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
