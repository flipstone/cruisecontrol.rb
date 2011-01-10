#
# RVM support
#
$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
require "rvm/capistrano"                  # Load RVM's capistrano plugin.
set :rvm_ruby_string, 'system'

#
# Bundler support
#
require "bundler/capistrano"

#
# Application environment defaults
# These should be set by the (environment) task, run first
#
set :rails_env, 'development'
set :instance, "localhost" 
set :branch, "master" 

#
# environment settings (by task)
#
desc "Runs any following tasks to production environment"
task :production do
  # sanity_check
  set :rails_env, "production"
  set :instance, "cruise.flipstone.com"
  set_servers
end

desc "Sets server IP/DNS values"
task :set_servers do
  role :web,      "#{instance}"
  role :app,      "#{instance}"
  role :db,       "#{instance}", :primary => true 
end

#
# Application settings (across all envs)
#
set :application, "cruisecontrol.rb"
set :deploy_to, "/srv/#{application}"
set :scm, "git"
set :local_scm_command, "git"
# set :scm_command, "GIT_SSH=#{deploy_to}/git_ssh.sh git"
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
  port: 8080,
  worker_processes: 1,
  worker_timeout: 15, #in seconds
  preload_app: false
}

set :nginx_cfg, {
  port: 80
}

#
# Deploy callbacks
#
before 'deploy:start', "deploy:unicorn_config"
