# frozen_string_literal: true
require "rubygems"
require "bundler/setup"
Bundler.require
require_relative 'osc_wave'

def print_hist_data(hist_data, stream = STDOUT)
  (0..(hist_data.last[0])).each do |period|
    val = hist_data.find { |p, c| p == period }
    val = 0 unless val
    stream.puts "#{period}, #{val[1]}"
  end
end

begin
  opts = Slop.parse do |o|
    o.string "-s", "--secrets", "secrets YAML file name", default: "secrets.yml"
    o.bool "-d", "--debug", "debug mode"
    o.bool "-v", "--verbose", "be verbose: list extra detail (unimplemented)"
    o.bool "-j", "--json", "output results in JSON"
    o.string "-h", "--highs", "filename to print HIGH histogram data to"
    o.string "-l", "--lows", "filename to print LOW histogram data to"
    o.bool "-c", "--create", "create the vm"
    o.bool "--pulses", "print the pulse list"
    o.bool "--list-images", "List available OS images"
    o.string "--region", "region to create the vm in"
    o.string "--config", "read cloud-init user data from given file"
    o.on "--help" do
      warn o
      exit
    end
  end
  config = YAML.safe_load_file(opts[:secrets])
  # Set up logging
  debug = opts.debug?
  logger = Logger.new($stderr)
  logger.level = config["loggerlevel"] ? eval(config["loggerlevel"]) : Logger::ERROR
  logger.level = Logger::DEBUG if debug

  filename = opts.args[0]
  logger.fatal("No data file given") if filename.nil?
  abort "No data file given" if filename.nil?
  wavedata = OscWave::Wave.new(filename, logger: logger)
  # puts d.inspect
  puts "Sample period: #{wavedata.format_time(wavedata.sample_period)}"

  wavedata.extract_levels
  pause = 0

  if opts[:highs]
    highs_hist = wavedata.levels.select { |l| l.level == true }
      .map { |l| l.period }.tally.sort_by { |p, c| c }
      .last(15).sort_by { |period, count| period }
    print_hist_data(highs_hist, File.open(opts[:highs], "w"))
  end

  if opts[:lows]
    lows_hist = wavedata.levels.select { |l| l.level == false }
      .map { |l| l.period }.tally.sort_by { |p, c| c }
      .last(15).sort_by { |period, count| period }
    print_hist_data(lows_hist, File.open(opts[:lows], "w"))
  end

end
