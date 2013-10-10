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

    def set_hostname_and_domain_name
      new_fqdn = URI(@ssh_uri).host
      new_hostname = new_fqdn.split(/^(\w*)\.*./)[1]
      
      display_ "Configuring hostname and domain name", :topic
      
      display_ "Set hostname..." do
        @server.hostname = new_hostname
      end

      display_ "Set domain name..." do
        @server.fqdn = new_fqdn
      end
    end

    def upload_local_user_key
      current_user = ENV['USER']
      
      display_ "Granting sysop and devop access to the current user", :topic
      
      display_ "Upload public key for '#{current_user}' user..." do
        @server.upload_sysop_key current_user, "#{ENV['HOME']}/.ssh/id_rsa.pub"
      end
      display_ "Upload public key for '#{current_user}' user..." do
        @server.upload_devop_key current_user, "#{ENV['HOME']}/.ssh/id_rsa.pub"
      end
    end

    def install_chef
      dependencies = "curl", "git", "build-essential", "libxml2-dev", "libxslt-dev"

      display_ "Installing Opscode Chef", :topic
      
      display_ "Install dependencies (#{dependencies.join(", ")})..." do
        @server.install dependencies
      end

      display_ "Install and configure chef-solo using omnibus..." do
        @server.install_chef
      end
    end

    def system_update
      display_ "Updating the system", :topic
      
      @server.update do |output|
        display_ output, :live
      end
    end

    def run_chef
      display_ "Configuring services using Chef", :topic

      @server.chef.run do |output|
        display_ output, :live
      end 
    end
  end
end