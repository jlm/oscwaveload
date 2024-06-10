# frozen_string_literal: true
require_relative 'osc_wave'

def level_name(level)
  if level
    "High"
  else
    "Low"
  end
end

d = OscWave.new(ARGV[0])
# puts d.inspect
puts "Sample period: #{format_time(d.sample_period)}"

while d.pos < d.data_points do
  p1 = { pos: d.pos, level: d.level }
  _next_edge = d.next_edge
  p2 = { pos: d.pos, level: d.level }
  puts "#{level_name(p1[:level])} for #{p2[:pos] - p1[:pos]} periods, \
#{format_time((d.sample_period * (p2[:pos] - p1[:pos])).round(4))}"
end
