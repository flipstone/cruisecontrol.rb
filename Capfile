load 'deploy' if respond_to?(:namespace) # cap2 differentiator
load 'config/deploy/deploy.rb'
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
Dir['config/deploy/*recipes.rb'].each { |recipe| load(recipe) }
