# frozen_string_literal: true
require "rubygems"
require "bundler/setup"
Bundler.require
require_relative 'osc_wave'
require "gr/plot"

def print_hist_data(data, level, filename)
  hist = data.levels.select { |l| l.start.level == level }
    .map { |l| l.period }.tally.sort_by { |p, c| c }
    .last(15).sort_by { |period, count| period }
  stream = File.open(filename, "w")
  (0..(data.last[0])).each do |period|
    val = data.find { |p, c| p == period }
    val = 0 unless val
    stream.puts "#{period}, #{val[1]}"
  end
  stream.close
end

def plot_raw(data, range, subplot_index, y_expansion = 1.4, figsize = [20, 4])
  from = range[0].to_i
  to = range[1].to_i
  ymin, ymax = (data.data.min * y_expansion).to_i, (data.data.max * y_expansion).to_i
  params = {
    figsize: figsize,
    xlim: [from, to],
    ylim: [ymin, ymax]
  }
  GR.plot(Array(from..(to)), data.data[from..to], params.merge(GR.subplot(2, 1, subplot_index)))
  pause = 0
end

def plot_levels(wavedata, range, subplot_index, xticks = [42, 2], figsize = [20, 4])
  from = range[0].to_i
  to = range[1].to_i
  ymin = -0.5
  ymax = 1.5
  params = {
    figsize: figsize,
    ylim: [ymin, ymax],
    xlim: [from, to],
    xticks: xticks
  }
  pos = 0
  xvals = []
  yvals = []
  wavedata.levels.each do |l|
    if l.start.level == :low
      xvals << pos += l.period; yvals << 0
      xvals << pos; yvals << 1
    else
      xvals << pos += l.period; yvals << 1
      xvals << pos; yvals << 0
    end
  end
  GR.plot(xvals, yvals, params.merge(GR.subplot(2, 1, subplot_index)))
  pause = 0
end

begin
  opts = Slop.parse do |o|
    o.string "-s", "--secrets", "secrets YAML file name", default: "secrets.yml"
    o.bool "-d", "--debug", "debug mode"
    o.bool "-v", "--verbose", "be verbose: list extra detail (unimplemented)"
    o.bool "-j", "--json", "output results in JSON"
    o.string "-h", "--highs", "filename to print HIGH histogram data to"
    o.string "-l", "--lows", "filename to print LOW histogram data to"
    o.bool "-w", "--wait", "wait forever at the end"
    o.bool "--pulses", "print the pulse list"
    o.array "--plotraw", "Plot raw data: start..finish", delimiter: ".."
    o.array "--plotlevels", "Plot level data: start..finish", delimiter: ".."
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
  logger.info "Sample period: #{wavedata.format_time(wavedata.sample_period)}"
  wavedata.extract_levels
  pause = 0

  print_hist_data(wavedata, :high, opts[:highs]) if opts[:highs]
  print_hist_data(wavedata, :low, opts[:lows]) if opts[:lows]
  plot_raw(wavedata, opts[:plotraw], 1) if opts[:plotraw].length == 2
  plot_levels(wavedata, opts[:plotlevels], 2, [42, 2]) if opts[:plotlevels].length == 2
  pause = 1

  # wavedata.find_pulse(0, :high, 38, 53)

  if opts.wait?
    logger.warn("Waiting around...")
    loop do
      sleep 60
    end
  end
end
