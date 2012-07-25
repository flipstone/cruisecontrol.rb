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
set :rvm_ruby_string, '1.9.2'

#
# environment settings (by task)
#
desc "Runs any following tasks to production environment"
task :production do
  set :rails_env, "production"
  set :instance, "nexus.flipstone.com"
  set :unicorn_port, 8081
  set :nginx_cfg, {
    port: 80,
    ht_user: "nexus",
    ht_passwd: "welcome1"
  }
  set_env
end

desc "Sets Capistrano environment variables after environment task runs"
task :set_env do
  role :web,      "#{instance}"
  role :app,      "#{instance}"
  role :db,       "#{instance}", :primary => true

  set :application, "cruisecontrol-solarnexus.rb"
  set :deploy_to, "/srv/#{application}"
  set :scm, "git"
  set :local_scm_command, "git"
  set :scm_passphrase, ""
  set :deploy_via, :remote_cache
  set :repository, "git://github.com/flipstone/cruisecontrol.rb.git"
  set :use_sudo, false
  set :user, "ubuntu"
  set :branch, "solarnexus"

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

task :symlink_root do
  run "test -d ~/.nexus-cruise && rm -rf ~/.nexus-cruise; echo ok"
  run "ln -sfT /mnt/big_space/solarnexus ~/.nexus-cruise"
end

before 'deploy:start', 'symlink_root'
before 'deploy:restart', 'symlink_root'

