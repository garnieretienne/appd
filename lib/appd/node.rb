require 'uri'
require 'appd/helpers'
require 'appd/server/system'

module Appd

  class Node
    include Appd::Helpers

    def initialize(ssh_uri)
      @ssh_uri = ssh_uri
      @server = Appd::Server::System.new @ssh_uri
    end

    # Bootstrap a new server
    def bootstrap

      display_ "Configuring hostname and domain name", :topic
      new_fqdn = URI(@ssh_uri).host
      new_hostname = new_fqdn.split(/^(\w*)\.*./)[1]
      
      display_ "Setting hostname..." do
        @server.hostname = new_hostname
      end

      display_ "Setting domain name..." do
        @server.fqdn = new_fqdn
      end

      display_ "Setup the creation of an admin user", :topic
      current_user = ENV['USER']
      
      display_ "Upload public key for '#{current_user}' user..." do
        @server.upload_admin_key current_user, "#{ENV['HOME']}/.ssh/id_rsa.pub"
      end

      display_ "Update the system", :topic
      
      @server.update do |output|
        display_ output, :live
      end

      display_ "Install Opscode Chef", :topic
      dependencies = :curl, :git
      
      display_ "Install dependencies (#{dependencies.join(", ")})..." do
        @server.install dependencies
      end

      display_ "Install and configure chef-solo using omnibus..." do
        @server.install_chef
      end

      display_ "Configure services using Chef", :topic

      @server.chef.run do |output|
        display_ output, :live
      end

      display_ "Done.", :topic
    end
  end
end