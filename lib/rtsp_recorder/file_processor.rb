require 'thread'

module RtspRecorder
  class FileProcessor

    attr_accessor :storage_dir, :queue

    def initialize(queue, storage_dir)
      @queue, @storage_dir = queue, storage_dir
    end

    def format_time(time)
      time.strftime('%Y-%m-%d-%H-%M-%S')
    end

    def filename(start, finish)
      "#{format_time(start.strftime)}---#{format_time(finish.strftime)}.mp4"
    end

    def run
      loop do
        file = queue.pop
        puts file
        if file[:trigger] == '1'
          File.rename(file[:filename], "#{storage_dir}/#{filename(file[:start], file[:finish])}" )
        else
          File.delete(file[:filename])
        end
      end
    end

    def start
      Thread.new { run }
    end

  end
end