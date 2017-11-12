require 'open3'

module RtspRecorder
  class Recorder

    attr_accessor :url, :record_dir

    def initialize(url, record_dir)
      @url, @record_dir = url, record_dir
      @stop = false
      @log = RtspRecorder.log
    end

    def count_files_size
      Dir.glob("#{record_dir}/*").reduce(0) do |memo, file|
        memo + (File.size?(file)||0)
      end
    end

    def rtsp_alive
      initial_size = count_files_size
      sleep(0.3)
      (count_files_size != initial_size) && @wait_thr.alive?
    end

    def start_rtsp
      @log.info "Start recording #{url} to #{record_dir}"
      cmd = %W(openRTSP -P 30 -F video -4 -c -B 10000000 -b 10000000 -H -w 1920 -h 1080 -f 15 -V #{url})
      @stdin, @stdout, @wait_thr = Open3.popen2e(*cmd, chdir: record_dir)
      @log.debug "Started, pid #{@wait_thr.pid}"
    end

    def kill_rtsp
      @log.info "Stop recording #{url}"
      begin
        Process.kill("HUP", @wait_thr.pid)
      rescue Errno::ESRCH
      end
      @stdin.close
      @stdout.close
    end

    def print_stdout
      @log.debug ' -------- openRTSP --------- '
      while line = @stdout.gets do
        @log.debug(line)
      end
      @log.debug ' --------------------------- '
    end

    def start
      start_rtsp
      sleep(3)
      Thread.new do
        loop do
          unless rtsp_alive
            print_stdout
            @log.info "Rtsp dead. Restarting."
            kill_rtsp
            start_rtsp
            sleep(3)
          end
          sleep(0.3)
          Thread.exit if @stop
        end
      end
    end

    def stop
      @stop = true
    end

  end
end
