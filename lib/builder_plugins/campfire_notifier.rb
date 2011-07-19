require 'tinder'

class CampfireNotifier
  VERSION = 0.2
  attr_accessor :room_name, :settings_scope

  def initialize(project = nil)
    @project = project
  end

  def self.settings
    YAML.load_file(File.join(RAILS_ROOT, "config", "campfire_notifier.yml")) rescue nil
  end
  
  def settings
    CampfireNotifier.settings[settings_scope]
  end
  
  def room
    self.room_name ||= settings["room"]
    return if room_name.nil?
    logger.debug("Campfire Notifier configured with #{settings.inspect}")
    campfire = Tinder::Campfire.new(settings["subdomain"], :ssl => settings["use_ssl"])
    campfire.login settings["login"], settings["password"]
    logger.debug("Logged in to campfire #{settings['subdomain']} as #{settings['login']}")
    campfire.find_room_by_name(room_name)
  rescue => e
    logger.error("Trouble initalizing campfire room #{room_name}")
    raise
  end
  
  def build_finished(build)
    clear_flag
    build_text = "Build #{build.label}"
    speak(build.failed? ? "#{build_text} broken" : "#{build_text} successful")
  end

  def build_fixed(build, previous_build=nil)
    clear_flag
    speak("Build fixed in #{build.label}")
  end
  
  def build_loop_failed(error)
    return if flagged? && is_subversion_down?(error)
    if is_subversion_down?(error)
      speak "Build loop failed: Error connecting to Subversion"
      set_flag
    else
      speak( "Build loop failed with: #{error.class}: #{error.message}")
      error.backtrace.each { |line| speak line } rescue nil
    end
  end

  def speak(message)
    room.speak(message) unless room_name.nil?
  rescue => e
    logger.error("Error speaking into campfire room #{room_name}")
    raise
  end
  
  def logger
    CruiseControl::Log
  end
  
  def flagged?
    File.exists?("#{@project.name}.svn_flag")
  end
    
  def set_flag
    File.open("#{@project.name}.svn_flag","w") do |file|
      file.puts "#{@project.name} subversion down"
    end
  end
  
  def clear_flag
    return unless flagged?
    File.delete("#{@project.name}.svn_flag")
    speak "Subversion is back"
  end
    
  def is_subversion_down?(error)
    /svn: PROPFIND request failed/.match(error.message)
  end

end

Project.plugin :campfire_notifier unless CampfireNotifier.settings.nil?