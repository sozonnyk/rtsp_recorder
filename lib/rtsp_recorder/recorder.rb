module RtspRecorder
 class Recorder

   attr_accessor :url, :record_dir

   def initialize(url, record_dir)
     @url, @record_dir = url, record_dir
   end

  def start
    puts "Start recording #{url} to #{record_dir}"
    fork do
      exec("cd #{record_dir} && openRTSP -P 30 -F video -4 -c -B 10000000 -b 10000000 -H -w 1920 -h 1080 -f 15 -V #{url}")
    end
  end
 end
end
