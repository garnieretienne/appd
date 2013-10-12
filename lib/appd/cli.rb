require 'thor'
require 'appd/commands/nodes'
require 'appd/commands/apps'
require 'appd/commands/config'

module Appd

  class CLI < Thor
    
    desc 'nodes', 'Manage servers'
    subcommand 'nodes', Appd::Commands::Nodes

    desc 'apps', 'Manage apps (create / destroy)'
    subcommand 'apps', Appd::Commands::Apps

    desc 'config', 'Manage app config vars'
    subcommand 'config', Appd::Commands::Config

  end
end