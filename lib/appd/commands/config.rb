require 'thor'
require 'appd/node'

module Appd

  module Commands

    class Config < Thor

      desc 'list', 'display the config vars for an app'
      def list
        app = Appd::App.new name: options[:app], node: "ssh://appd@#{options[:node]}"
        app.list_config
      end
      # default_task :list

      desc 'set KEY=VALUE', 'set one or more config vars'
      def set(config)
        key, value = config.split('=')
        app = Appd::App.new name: options[:app], node: "ssh://appd@#{options[:node]}"
        app.set_config key, value
      end

      desc 'unset KEY', 'unset one or more config vars'
      def unset(key)
        app = Appd::App.new name: options[:app], node: "ssh://appd@#{options[:node]}"
        app.unset_config key
      end
    end
  end
end