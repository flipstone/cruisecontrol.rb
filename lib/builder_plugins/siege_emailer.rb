class SiegeEmailer < BuilderPlugin
  attr_accessor :emails
  attr_writer :from

  SUFFIX = "-siege"
  
  def initialize(project = nil)
    @emails = []
  end

  def from
    @from || Configuration.email_from
  end

  def build_finished(build)
    return if @emails.empty? || ! build.project.name.include?(SUFFIX)
    if (!build.failed?)
      env_name = build.project.name.gsub(SUFFIX,'').upcase!
      email :deliver_terse_report, build, "Siege test results available for #{env_name}",
            "Load testing complete.  Full history available as build artifacts in link."
    end
  end  
  
  private
  
  def email(template, build, *args)
    BuildMailer.send(template, build, @emails, from, *args)
  rescue
    settings = ActionMailer::Base.smtp_settings.map { |k,v| "  #{k.inspect} = #{v.inspect}" }.join("\n")
    raise
  end

end

Project.plugin :siege_emailer