require 'thor'
require 'appd/commands/node'
require 'appd/commands/app'
require 'appd/commands/config'

module Appd

  # The Appd CLI
  class CLI < Thor
    
    desc 'node', 'Manage server configuration'
    subcommand 'node', Appd::Commands::Node

    desc 'app', 'Manage app configuration'
    subcommand 'app', Appd::Commands::App

    option :node, required: true
    option :app, required: true
    desc 'config', "manage app config vars"
    subcommand 'config', Appd::Commands::Config
  end
end