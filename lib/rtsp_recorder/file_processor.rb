require 'thread'
require 'fileutils'

module RtspRecorder
  class FileProcessor

    attr_accessor :storage_dir, :queue

    def initialize(queue, storage_dir)
      @queue, @storage_dir = queue, storage_dir
      @stop = false
      @log = RtspRecorder.log
    end

    def format_time(time)
      time.strftime('%Y-%m-%d-%H-%M-%S')
    end

    def filename(start, finish)
      "#{format_time(start)}---#{format_time(finish)}.mp4"
    end

    def run
      loop do
        begin
          file = queue.pop(true)
          if RtspRecorder.test_trigger(file[:trigger])
            @log.info "Store #{file[:filename]} to #{storage_dir}/#{filename(file[:start], file[:finish])} "
            FileUtils.move(file[:filename], "#{storage_dir}/#{filename(file[:start], file[:finish])}" )
          else
            @log.info "Delete #{file[:filename]}"
            FileUtils.rm_f(file[:filename])
          end
        rescue ThreadError
          Thread.current.exit if @stop
          sleep(0.05)
        end
      end
    end

    def start
      Thread.new { run }
    end

    def stop
      @stop = true;
    end

  end
end