require 'socket'
require 'ipaddr'
require 'thread'

module RtspRecorder
  class MulticastListener

    MULTICAST_ADDR = "224.1.1.1"
    PORT = 5007

    def process_message(msg)
      camera_name, trigger_state = msg.split(',')
      RtspRecorder.mutex.synchronize do
        RtspRecorder.file_registry[camera_name] = {} unless RtspRecorder.file_registry[camera_name]
        RtspRecorder.file_registry[camera_name][:trigger] = trigger_state
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
        msg, info = sock.recvfrom(1024)
        puts "MSG: #{msg} from #{info[2]} (#{info[3]})/#{info[1]}"
        process_message(msg)
      end
    end

    def start
      Thread.new { run }
    end

  end
end
