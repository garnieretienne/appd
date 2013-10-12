require 'thor'
require 'appd/helpers'
require 'appd/app'

module Appd

  module Commands

    class Config < Thor
      include Appd::Helpers

      desc "list", "Display the config vars for an app"
      option :node, required: true
      option :app, required: true
      def list
        app = Appd::App.new name: options[:app], node: options[:node]

        display_ "Displaying config vars for '#{app.name}'", :topic

        display_ app.list_config
        
      end

      desc "set KEY1=VALUE1 [KEY2=VALUE2 ...]", "Set one or more config vars"
      option :node, required: true
      option :app, required: true
      def set(*config_vars)
        app = Appd::App.new name: options[:app], node: options[:node]

        display_ "Setting config vars for '#{app.name}'", :topic

        config_vars.each do |config_var|
          key, value = config_var.split('=')
          raise "Bad config var format" if key.nil? || value.nil?
          
          display_ "set #{key}..." do
            app.set_config key, value
          end
        end

        display_ "restart the app..." do
          app.release
        end
      end

      desc "unset KEY1 [KEY2 ...]", "Unset one or more config vars"
      option :node, required: true
      option :app, required: true
      def unset(*keys)
        app = Appd::App.new name: options[:app], node: options[:node]

        display_ "Unsetting config vars for '#{app.name}'", :topic

        keys.each do |key|
          display_ "unset #{key}..." do
            app.unset_config key
            "done"
          end
        end

        display_ "restart the app..." do
          app.release
        end
      end
    end
  end
end