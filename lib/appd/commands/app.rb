require 'thor'
require 'appd/app'

module Appd

  module Commands

    class App < Thor

      desc "create NAME", "Create an application on the server"
      method_option :node, aliases: "-n", desc: 'node on which the app will be published (host[:port])', required: true
      def create(name)
        app = Appd::App.new name: name, node: "ssh://appd@#{options[:node]}"
        app.create
      end

    end
  end
end