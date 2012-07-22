Hisaishi.controllers do
  disable :layout

  # /
  get :index do
    # Choose Player or Controller
    @app_url = "http://#{HostHelpers.my_first_non_loopback_ipv4}:#{settings.port}/"
    render 'root/index'
  end

  # /socket
  get :socket do
    return redirect(url(:index)) if !request.websocket?

    hi_json  = {type: 'hi'}.to_json
    bye_json = {type: 'bye'}.to_json

    request.websocket do |ws|
      ws.onopen do
        ws.send(hi_json)
        settings.socket_pool.sockets << ws
      end
      ws.onmessage do |msg|
        EM.next_tick do
          # Spam the message back out to all connected clients, player and controller alike.
          settings.socket_pool.sockets.each do |s|
            s.send(msg)
          end
        end
      end
      ws.onclose do
        ws.send(bye_json)
        settings.socket_pool.sockets.delete(ws)
      end
    end
  end

end
