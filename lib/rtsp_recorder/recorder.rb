require 'open3'

module RtspRecorder
 class Recorder

   attr_accessor :url, :record_dir

   def initialize(url, record_dir)
     @url, @record_dir = url, record_dir
   end

  def start
    puts "Start recording #{url} to #{record_dir}"
    cmd = %W(openRTSP -P 30 -F video -4 -c -B 10000000 -b 10000000 -H -w 1920 -h 1080 -f 15 -V #{url})
    @stdin, @stdout, @stderr, wait_thr = Open3.popen3(cmd, chdir: record_dir)
    @pid = wait_thr[:pid]
    puts "Rtarted, pid #{@pid}"
  end

   def stop
     puts "Stop recording #{url}"
     Process.kill("HUP", @pid)
     @stdin.close
     @stdout.close
     @stderr.close
   end

 end
end
