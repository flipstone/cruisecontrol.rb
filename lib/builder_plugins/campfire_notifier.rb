require 'httparty'
require 'json'

class CampfireNotifier < BuilderPlugin

  def initialize(project = nil)
    @rooms = []
  end

  def build_finished(build)
    return if @rooms.empty?
    notify build
  end

  def room(room_number)
    @rooms << room_number
  end

  def notify(build)
    @rooms.each  do |roomnumber|
      room = Campfire.room(roomnumber)
      room.join
      room.lock
        
      room.message 'Cruise build finished:'
      room.paste "BUILD #{build.status}"
      room.play_sound 'rimshot'
    
      room.unlock
      room.leave
    end
  end

  # from http://developer.37signals.com/campfire/
  class Campfire
    include HTTParty

    base_uri   'https://37s.campfirenow.com'
    basic_auth '73d3108ab61da924ac3407d6b4169a13877d10e9', 'x'
    headers    'Content-Type' => 'application/json'

    def self.rooms
      Campfire.get('/rooms.json')["rooms"]
    end

    def self.room(room_id)
      Room.new(room_id)
    end

    def self.user(id)
      Campfire.get("/users/#{id}.json")["user"]
    end
  end

  class Room
    attr_reader :room_id

    def initialize(room_id)
      @room_id = room_id
    end

    def join
      post 'join'
    end

    def leave
      post 'leave'
    end

    def lock
      post 'lock'
    end

    def unlock
      post 'unlock'
    end

    def message(message)
      send_message message
    end

    def paste(paste)
      send_message paste, 'PasteMessage'
    end

    def play_sound(sound)
      send_message sound, 'SoundMessage'
    end

    def transcript
      get('transcript')['messages']
    end

    private

    def send_message(message, type = 'Textmessage')
      post 'speak', :body => {:message => {:body => message, :type => type}}.to_json
    end

    def get(action, options = {})
      Campfire.get room_url_for(action), options
    end

    def post(action, options = {})
      Campfire.post room_url_for(action), options
    end

    def room_url_for(action)
      "/room/#{room_id}/#{action}.json"
    end
  end

end

Project.plugin :campfire_emailer