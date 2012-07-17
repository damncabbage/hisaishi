require 'rubygems'
require 'sinatra/base'
require 'sinatra/jsonp'
require 'natural_time'
require 'socket'
require 'thin'
require 'em-websocket'

EventMachine.run do
  @channel = EM::Channel.new
 
  EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 8080) do |ws|
      ws.onopen {
        sid = @channel.subscribe { |msg| ws.send msg }
        @channel.push "#{sid} connected!"
 
        ws.onmessage { |msg|
          @channel.push "<#{sid}>: #{msg}"
        }
 
        ws.onclose {
          @channel.unsubscribe(sid)
        }
      }
 
  end
 
  App.run!({:port => 3000})
end