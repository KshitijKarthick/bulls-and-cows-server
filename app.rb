require 'thin'
require 'em-websocket'
require 'sinatra/base'


def uid(ws)
	return ws.object_id
end

EM.run do
	class App < Sinatra::Base
		get '/' do
			erb :index
		end
		not_found do
 			 erb :index
		end
	end

	@opponents = Hash.new(nil)
	@userwaiting = nil

	EM::WebSocket.start(:host => '0.0.0.0', :port => '3001') do |ws|
		ws.onopen do |handshake|
			
			if @userwaiting == nil
				@userwaiting = ws
				@userwaiting.send "userid: #{uid(@userwaiting)}"
			else	
			#There is a user waiting to be paired up
			@opponents[uid(ws)] = { 'oppid' => uid(@userwaiting), 'socket' => @userwaiting}
			@opponents[uid(@userwaiting)] = {'oppid'=> uid(ws), 'socket' => ws} 
			ws.send "userid: #{uid(ws)}"
			ws.send "opponentid: #{uid(@userwaiting)}"
			@userwaiting.send "opponentid: #{uid(ws)}"
			@userwaiting = nil
			end
		end

		ws.onclose do 
			opp = @opponents[uid(ws)]
			opp['socket'].send 'message: Opponent disconnected. Close the socket to bugger off.'
			oppid = opp['oppid']
			@opponents.delete oppid
			@opponents.delete uid(ws)		
		end

		ws.onmessage do |msg|
			if @opponents[uid(ws)] == nil
				ws.send 'You have no opponent yet, please wait.'
			else
				@opponents[uid(ws)]['socket'].send msg
			end
		end
	end

	App.run! :port => 3000
end