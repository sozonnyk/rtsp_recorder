require 'rb-inotify'
require 'thread'

module RtspRecorder

  class FileListener
    attr_accessor :camera_name, :watch_dir, :queue

    def initialize(camera_name, watch_dir)
      @camera_name, @watch_dir = camera_name, watch_dir
    end

    def full_filename(filename)
      "#{watch_dir}/#{filename}"
    end

    def update_file_registry
      RtspRecorder.mutex.synchronize do
        yield
      end
    end

    def run
        notifier = INotify::Notifier.new
        notifier.watch(watch_dir, :close_write, :create) do |event|
          puts event
          case
            when event.contain?(:create)
              update_file_registry do
                RtspRecorder.file_registry[camera_name] =
                    {filename: full_filename(filename),
                     start: Time.now,
                     trigger: RtspRecorder.trigger_registry[camera_name]}
              end
              create_file(event.name)
            when event.contaim?(:close_write)
              update_file_registry do
                file = RtspRecorder.file_registry[camera_name]
                file[:finish] = Time.now
                RtspRecorder.completed_files_queue << file
              end
          end
        end
        notifier.run
    end

    def start
      @queue = Queue.new
      Thread.new { run }
      @queue
    end

  end

end



