require 'thor'
require 'appd/app'

module Appd

  module Commands

    class Apps < Thor

      desc "create NAME", "Create an application on the server"
      option :node, required: true
      option :app, required: true
      def create(name)
        app = Appd::App.new name: name, node: "ssh://appd@#{options[:node]}"
        app.create
      end
    end
  end
end