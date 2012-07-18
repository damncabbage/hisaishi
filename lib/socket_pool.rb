class SocketPool
  attr_accessor :sockets

  def initialize
    @sockets = []
  end

  def send_to_all(type, data={})
    sockets.each do |ws|
      ws.send({:type => type, :data => data}.to_json)
    end
  end
end
