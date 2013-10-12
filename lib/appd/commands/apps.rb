require 'thor'
require 'appd/helpers'
require 'appd/app'

module Appd

  module Commands

    class Apps < Thor
      include Appd::Helpers

      desc "create", "Create an application on the server"
      option :node, required: true
      option :app, required: true
      def create
        app = Appd::App.new name: options[:app], node: options[:node]

        display_ "Creating the '#{app.name}' application", :topic

        display_ "create the git repository..." do
          app.create
        end
      end
    end
  end
end