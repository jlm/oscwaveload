# frozen_string_literal: true

# Copyright (c) 2024 John Messenger. All rights reserved.

require_relative "./frame"

# Parse a wave into frames
class WaveParse
  attr_reader :frames

  def initialize(wave, logger: Logger.new(STDOUT))
    @wave = wave
    @logger = logger
  end

  def extract_frames(frame_gap_width, start = 0, finish = @wave.data_points)
    @frame_gap_width = frame_gap_width
    @frames = []
    pos = @wave.find_pulse(start, :low, frame_gap_width, { complain: 'Gap before first frame' }).end
    while pos < finish
      frame_number = @frames.length
      @logger.debug("Frame #{frame_number} starts at #{pos}")
      end_of_frame = @wave.find_pulse(pos, :low, frame_gap_width)
      break unless end_of_frame

      length = end_of_frame.end - pos
      @frames << Frame.new(@wave, pos, end_of_frame, length, logger: @logger)
      @logger.info("Frame #{frame_number}: #{@frames.last}, length: #{length} or #{@wave.format_time(length * @wave.sample_period)}")
      pos = end_of_frame.end
    end
    @frames
  end

end
