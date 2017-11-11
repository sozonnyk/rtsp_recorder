require 'socket'
require 'ipaddr'
require 'thread'

module RtspRecorder
  class MulticastListener

    MULTICAST_ADDR = "224.1.1.1"
    PORT = 5007

    def initialize
      @stop = false
    end

    def find_camera_name(trigger_name)
      RtspRecorder.config['cameras'].detect do |camera|
        break camera['name'] if trigger_name == camera['trigger']
      end
    end

    def process_message(msg)
      trigger_name, trigger_state = msg.split(',')
      camera_name = find_camera_name(trigger_name)
      unless camera_name
        puts "Trigger #{trigger_name} doesn't have corresponding camera"
        return
      end
      RtspRecorder.mutex.synchronize do
        RtspRecorder.file_registry[camera_name] = {} unless RtspRecorder.file_registry[camera_name]
        RtspRecorder.file_registry[camera_name][:trigger] = trigger_state if RtspRecorder.test_trigger(trigger_state)
        RtspRecorder.trigger_registry[camera_name] = trigger_state
      end
    end

    def run
      puts "Start listening for multicast"
      ip = IPAddr.new(MULTICAST_ADDR).hton + IPAddr.new("0.0.0.0").hton
      sock = UDPSocket.new
      sock.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, ip)
      sock.bind(Socket::INADDR_ANY, PORT)
      loop do
        begin
          msg, info = sock.recvfrom_nonblock(1024)
        rescue IO::WaitReadable, IO::EAGAINWaitReadable
          break if @stop
          IO.select([sock])
          sleep(0.05)
          retry
        end
        puts "MSG: #{msg} from #{info[2]} (#{info[3]})/#{info[1]}"
        process_message(msg)
      end
    end

    def start
      Thread.new { run }
    end

    def stop
      @stop = true
    end

  end
end
