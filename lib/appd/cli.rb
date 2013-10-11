require 'thor'
require 'appd/commands/nodes'

module Appd

  class CLI < Thor
    
    desc 'nodes', 'manage servers'
    subcommand 'nodes', Appd::Commands::Nodes

  end
end