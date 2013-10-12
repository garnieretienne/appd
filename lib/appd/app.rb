require "appd/client"

module Appd

  class App

    # User used to run the devops commands
    APPD_USER = "appd"

    attr_accessor :node, :name

    def initialize(options={})
      raise ArgumentError, "No node address provided" if !options[:node]
      raise ArgumentError, "No name provided" if !options[:node]
      options.each{|option, value| self.send("#{option}=", value)}
      @api = Appd::Client.new ssh_uri
    end

    # Build a SSH URI (ssh://`APPD_USER`@hostname:port)
    def ssh_uri
      "ssh://#{APPD_USER}@#{@node}"
    end

    # Create an application on the node
    def create
      @api.create @name
    end
  end
end