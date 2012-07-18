Hisaishi.helpers do
  def send_to_sockets(type, for_who, action, data={})
    data[:for]    = for_who || "player"
    data[:action] = action
    settings.socket_pool.send_to_all(type, data)
  end
end
