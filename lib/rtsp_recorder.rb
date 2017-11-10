require "rtsp_recorder/recorder"
require "rtsp_recorder/file_listener"
require "rtsp_recorder/file_processor"
require "rtsp_recorder/multicast_listener"
require "rtsp_recorder/version"

require "fileutils"

module RtspRecorder

  CONFIG = {'camera1' => {url: 'rtsp://camera/unicast', record_dir: '/ram/camera1', storage_dir: '/mnt/camera1'}}

  def self.file_registry
    #{camera_name => {filename: start: finish: trigger:}
    @@file_registry ||= {}
  end

  def self.trigger_registry
    #{camera_name => trigger_state}
    @@trigger_registry ||= {}
  end

  def self.mutex
    @@mutex ||= Mutex.new
  end

  def self.start
    MulticastListener.new.start

    CONFIG.each do |camera_name, camera_options|
      FileUtils::mkdir_p(camera_options[:storage_dir])
      FileUtils::mkdir_p(camera_options[:record_dir])
      FileUtils::rm_f(Dir.glob("#{camera_options[:record_dir]}/*"))

      queue = FileListener.new(camera_name, camera_options[:record_dir]).start
      FileProcessor.new(queue, camera_options[:storage_dir]).start
      Recorder.new(camera_options[:url], camera_options[:record_dir]).start
    end

    # Wait for all threads to end
    Thread.list.each do |t|
      # Wait for the thread to finish if it isn't this thread (i.e. the main thread).
      t.join if t != Thread.current
    end
  end
end
