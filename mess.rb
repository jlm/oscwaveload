# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
Bundler.require
require_relative 'osc_wave'
require 'gr/plot'

def print_hist_data(data, level, filename)
  hist = data.levels.select { |l| l.start.level == level }
    .map(&:period).tally.sort_by { |_p, c| c }
    .last(15).sort_by { |period, _count| period }
  stream = File.open(filename, 'w')
  (0..(hist.last[0])).each do |period|
    val = hist.find { |p, _c| p == period }
    val ||= 0
    stream.puts "#{period}, #{val[1]}"
  end
  stream.close
end

def plot_raw(data, range, subplot_index, y_expansion = 1.4, figsize = [20, 4])
  from = range[0].to_i
  to = range[1].to_i
  ymin, ymax = (data.data.min * y_expansion).to_i, (data.data.max * y_expansion).to_i
  params = {
    figsize:,
    xlim: [from, to],
    ylim: [ymin, ymax]
  }
  GR.plot(Array(from..(to)), data.data[from..to], params.merge(GR.subplot(2, 1, subplot_index)))
  _pause = 0
end

def plot_levels(wavedata, range, subplot_index, xticks = [42, 2], figsize = [20, 4])
  from = range[0].to_i
  to = range[1].to_i
  ymin = -0.5
  ymax = 1.5
  params = {
    figsize:,
    ylim: [ymin, ymax],
    xlim: [from, to],
    xticks:
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
  _pause = 0
end

begin
  opts = Slop.parse do |o|
    o.string '-s', '--secrets', 'secrets YAML file name', default: 'secrets.yml'
    o.bool '-d', '--debug', 'debug mode'
    o.bool '-v', '--verbose', 'be verbose: list extra detail (unimplemented)'
    o.bool '-j', '--json', 'output results in JSON'
    o.string '-h', '--highs', 'filename to print HIGH histogram data to'
    o.string '-l', '--lows', 'filename to print LOW histogram data to'
    o.bool '-w', '--wait', 'wait forever at the end'
    o.bool '--pulses', 'print the pulse list'
    o.array '--plotraw', 'Plot raw data: start..finish', delimiter: '..'
    o.array '--plotlevels', 'Plot level data: start..finish', delimiter: '..'
    o.string '--region', 'region to create the vm in'
    o.string '--config', 'read cloud-init user data from given file'
    o.on '--help' do
      warn o
      exit
    end
  end
  config = YAML.safe_load_file(opts[:secrets])
  # Set up logging
  debug = opts.debug?
  logger = Logger.new($stderr)
  logger.level = config['loggerlevel'] ? eval(config['loggerlevel']) : Logger::ERROR
  logger.level = Logger::DEBUG if debug

  filename = opts.args[0]
  logger.fatal('No data file given') if filename.nil?
  abort 'No data file given' if filename.nil?

  w = OscWave::Wave.new(filename, logger:)
  logger.info "Sample period: #{w.format_time(w.sample_period)}"
  w.extract_levels
  _pause = 0

  print_hist_data(w, :high, opts[:highs]) if opts[:highs]
  print_hist_data(w, :low, opts[:lows]) if opts[:lows]
  plot_raw(w, opts[:plotraw], 1) if opts[:plotraw].length == 2
  plot_levels(w, opts[:plotlevels], 2, [42, 2]) if opts[:plotlevels].length == 2

  pos = w.find_pulse(0, :low, 1000, 5000, { complain: 'Gap before first frame' })
  logger.info("First frame starts at #{pos.end}")
  end_of_frame = w.find_pulse(pos.end, :low, 1000, 5000, { complain: 'Gap before second frame' })
  logger.info("First frame ends at #{end_of_frame}")
  chars = []
  while pos < end_of_frame
    pos = w.find_pulse(pos, :high, 37, 53, { complain: 'Start of character' })
    logger.info("Start of character at #{pos}")
    nextcharpos = w.find_pulse(pos.end, :high, 37, 53, { complain: 'Start of next character' })
    logger.info("Length of character: #{nextcharpos - pos} or #{w.format_time((nextcharpos - pos) * w.sample_period)}")
    chars << { start: pos, end: nextcharpos }
    pos = nextcharpos.end
  end
  logger.info("Frame had #{chars.length} characters")
  _pause = 3

  if opts.wait?
    logger.warn('Waiting around...')
    loop do
      sleep 60
    end
  end
end
