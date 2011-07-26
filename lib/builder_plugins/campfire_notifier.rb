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
  gem 'httparty'
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
    notify(build)
  end

  def build_fixed(fixed_build, previous_build)
    notify(fixed_build, "fixed")
  end

  def notification_message(build, status)
    statustext = status || (build.failed? ? "broken" : "passed")
    committer = build.project.source_control.latest_revision.author
    mailmatched = /(.*) +(<.*\@.*)/.match committer
    committer_name = (mailmatched ? mailmatched[1] : committer)
    message = "[Build #{build.project.name}] (#{build.elapsed_time}) #{statustext.upcase} - #{committer_name}"
    if Configuration.dashboard_url
      message += " : #{build.url}"
    end
    message
  end


  def notify(build, status=nil)
    message = notification_message(build, status)

    if connect
      begin
        CruiseControl::Log.event("Campfire notifier: sending notice: '#{message}'", :info)
        @chat_room.speak(message)
      ensure
        disconnect rescue nil
      end
    else
      CruiseControl::Log.event("Campfire notifier: couldn't connect to send notice: '#{message}'", :warn)
    end
  end

end

Project.plugin :campfire_notifier