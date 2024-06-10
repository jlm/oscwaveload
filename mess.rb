# frozen_string_literal: true
require_relative 'osc_wave'

d = OscWave::Wave.new(ARGV[0])
# puts d.inspect
puts "Sample period: #{d.format_time(d.sample_period)}"

d.extract_levels
pause = 0
hist_data = Array([0,0])
highs_hist = d.levels.select {|l| l.level == true} .map {|l| l.period}.tally.sort_by {|p,c| c}
  .last(15).sort_by {|period, count| period}
lows_hist = d.levels.select {|l| l.level == false} .map {|l| l.period}.tally.sort_by {|p,c| c}
  .last(15).sort_by {|period, count| period}
pause = 1

def print_hist_data(hist_data, stream = STDOUT)
  (0..(hist_data.last[0])).each do |period|
    val = hist_data.find { |p, c| p == period }
    val = 0 unless val
    stream.puts "#{period}, #{val[1]}"
  end
end

print_hist_data(highs_hist, File.open("highs.csv", "w"))
print_hist_data(lows_hist, File.open("lows.csv", "w"))
