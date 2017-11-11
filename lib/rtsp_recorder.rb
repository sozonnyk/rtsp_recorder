require "rtsp_recorder/recorder"
require "rtsp_recorder/file_listener"
require "rtsp_recorder/file_processor"
require "rtsp_recorder/multicast_listener"
require "rtsp_recorder/version"

require "fileutils"
require 'yaml'

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

  def self.test_trigger(trigger)
    trigger == 'ON'
  end

  def self.config
    @config ||= Psych.load_file(File.expand_path('../../rtsp_recorder.yml', __FILE__))
  end

  def self.start
    Thread.abort_on_exception=true

    multicast_listener = MulticastListener.new
    multicast_listener.start

    config['cameras'].each do |camera|
      camera_name = camera['name']
      url = camera['url']
      storage_dir = "#{config['storage_dir']}/#{camera_name}"
      record_dir = "#{config['record_dir']}/#{camera_name}"
      FileUtils::mkdir_p(storage_dir)
      FileUtils::mkdir_p(record_dir)
      FileUtils::rm_f(Dir.glob("#{record_dir}/*"))

      file_listener = FileListener.new(camera_name, record_dir)
      file_processor = FileProcessor.new(file_listener.queue, storage_dir)
      recorder = Recorder.new(url, record_dir)

      camera[:file_listener] = file_listener
      camera[:file_processor] = file_processor
      camera[:recorder] = recorder

      file_processor.start
      file_listener.start
      recorder.start
    end

    trap('INT') do
      puts 'Shutting down'
      multicast_listener.stop
      config['cameras'].each do |camera|
        camera[:recorder].stop
        sleep(0.3)
        camera[:file_listener].stop
        sleep(0.3)
        camera[:file_processor].stop
      end
    end

    Thread.list.each do |t|
      t.join if t != Thread.current
    end
  end
end
