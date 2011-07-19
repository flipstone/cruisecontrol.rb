#
# Add the following to your individual project cruise_config.rb
# 
# project.campfire_notifier.subdomain = 'flipstone'
# project.campfire_notifier.token = 'xxxxasdfasdfas23412346'
# project.campfire_notifier.room = 'Chat Room'
#
#

begin
  require 'rubygems'
  gem 'httparty','~>0.4.3'
rescue
  CruiseControl::Log.event("Requires httparty gem ~>0.4.5, =0.4.5 and =5.0.0 don't work", :fatal)
  exit
end

begin
  require 'tinder'
rescue LoadError
  CruiseControl::Log.event("Campfire notifier: Unable to load 'tinder' gem.", :fatal)
  CruiseControl::Log.event("Install the tinder gem with: sudo gem install tinder", :fatal)
  exit
end

class CampfireNotifier < BuilderPlugin
  attr_accessor :subdomain, :room, :token, :campfire

  def initialize(project = nil)
  end

  def connect
    unless @subdomain
      CruiseControl::Log.event("Failed to load Campfire notifier plugin settings.  See the README in the plugin for instructions.", :warn)
      return false
    end
    CruiseControl::Log.event("Campfire notifier: connecting to #{@subdomain}", :debug)
    @campfire = Tinder::Campfire.new(@subdomain, token: @token)

    CruiseControl::Log.event("Campfire notifier: finding room: #{@room}", :debug)
    @chat_room = @campfire.find_room_by_name(@room)
  end

  def disconnect
    CruiseControl::Log.event("Campfire notifier: disconnecting from #{@subdomain}", :debug)
    @campfire.logout if defined?(@campfire) && @campfire.logged_in?
  end

  def reconnect
    disconnect
    connect
  end

  def connected?
    defined?(@campfire) && @campfire.logged_in?
  end

  def build_finished(build)
    notify(build) # if build.failed?
  end

  def build_fixed(fixed_build, previous_build)
    notify(fixed_build)
  end

  def notification_message(build)
    status = build.failed? ? "broken" : "fixed"
    message = "Cruise build #{build.project.name} #{status.upcase}: "
    if Configuration.dashboard_url
      message += "#{build.url}"
    end
    message
  end

  def notify(build)
    message = notification_message(build)

    if connect
      begin
        CruiseControl::Log.event("Campfire notifier: sending notice: '#{message}'", :info)
        @chat_room.speak(message)
        @chat_room.paste("#{message}\n#{build.changeset}")
      ensure
        disconnect rescue nil
      end
    else
      CruiseControl::Log.event("Campfire notifier: couldn't connect to send notice: '#{message}'" :warn)
    end
  end
end

Project.plugin :campfire_notifier