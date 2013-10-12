require 'thor'
require 'appd/commands/nodes'
require 'appd/commands/apps'

module Appd

  class CLI < Thor
    
    desc 'nodes', 'Manage servers'
    subcommand 'nodes', Appd::Commands::Nodes

    desc 'apps', 'Manage apps (create / destroy)'
    subcommand 'apps', Appd::Commands::Apps

  end
end