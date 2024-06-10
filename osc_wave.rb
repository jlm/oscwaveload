# frozen_string_literal: true
require 'unitwise'

def format_time(time)
  units = %w[s ms µs ns ps]
  negative = time < 0.0
  time = -time if negative

  units.each do |unit|
    if time > 1.0
      return (negative ? "-" : "") + time.to_s + " " + unit
    else
      time = time * 1000.0
    end
  end
end

def multiplier(num, mul)
  table = {
    'k': 1000,
    'M': 1000*1000,
    'G': 1000*1000*1000,
    'T': 1000*1000*1000*1000
  }
  multiplier = table[mul.to_sym]
  num *= multiplier if multiplier
  num
end

class OscWave
  attr_accessor :timebase, :rate, :amplitude, :amplres, :data_unit, :data_points, :data, :pos

  FLOAT_REGEX = /(([1-9][0-9]*\.?[0-9]*)|(\.[0-9]+))([Ee][+-]?[0-9]+)?/

  def parse_float_unit(str)
    number = str.match(FLOAT_REGEX)[0]
    unit = str.split(FLOAT_REGEX)[-1]
    Unitwise(number, unit)
  end

  def initialize(wave)
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
  end

  def sample_period
    rate = @rate[0..-5]
    rate = multiplier(rate.to_f, rate[-1])
    1.0 / rate
  end

  def next_low
    return nil unless @pos < @data_points
    ((@pos+1)..@data_points).each do |pos|
      if @data[pos] < @low_t
        return @pos = pos
      end
    end
  end

  def next_high
    return nil unless @pos < @data_points
    ((@pos+1)..@data_points).each do |pos|
      if @data[pos] > @high_t
        return @pos = pos
      end
    end
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

  def level
    if @data[@pos] < @low_t
      false
    elsif @data[@pos] > @high_t
      true
    else
      raise OscWave::Indeterminate, "Indeterminate level not outside range #{@low_t} to #{@high_t}"
    end
  end

  def extract_levels
    pos = 0
    @levels = []
    while pos < data_points do
      p1 = { pos: pos, level: level }
      _next_edge = next_edge
      p2 = { pos: pos, level: level }
      period = p2[:pos] - p1[:pos]
      puts "#{level_name(p1[:level])} for #{period} periods, #{format_time((sample_period * period).round(4))}"
      @levels
    end

  end
end
