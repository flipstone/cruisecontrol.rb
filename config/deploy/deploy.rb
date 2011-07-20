#
# Flipstone deployment recipes
#
require "flipstone-deployment/capistrano"

#
# Application environment defaults
# These should be set by the (environment) task, run first
#
# set :rails_env, 'development'
set :instance, "localhost" 
set :branch, "master" 
set :deployment_safeword, "easypeasy"

#
# environment settings (by task)
#
desc "Runs any following tasks to production environment"
task :production do
  set :rails_env, "production"
  set :instance, "cruise.flipstone.com"
  set :unicorn_port, 8080
  set :nginx_cfg, {
    port: 80,
    ht_user: "cruise",
    ht_passwd: "welcome1"
  }
  set_env
end

desc "Sets Capistrano environment variables after environment task runs"
task :set_env do
  role :web,      "#{instance}"
  role :app,      "#{instance}"
  role :db,       "#{instance}", :primary => true 

  set :application, "cruisecontrol.rb"
  set :deploy_to, "/srv/#{application}"
  set :scm, "git"
  set :local_scm_command, "git"
  set :scm_passphrase, ""
  set :deploy_via, :remote_cache
  set :repository, "git://github.com/flipstone/#{application}.git"
  set :use_sudo, false
  set :user, "ubuntu"

  ssh_options[:keys] = ["#{ENV['HOME']}/.ssh/fs-remote.pem"]
  ssh_options[:paranoid] = false
  ssh_options[:user] = "ubuntu"

  default_run_options[:pty] = true

  set :unicorn, {
    port: unicorn_port,
    worker_processes: 2,
    worker_timeout: 15, #in seconds
    preload_app: false
  }

end
