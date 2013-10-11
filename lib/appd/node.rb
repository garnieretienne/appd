require 'appd/remote_host'
require 'appd/chef_instance'

module Appd

  class Node

    # Where sysops pub keys are stored on the node
    SYSOPS_KEYS_PATH = "/root/sysops"

    # Where devops pub keys are stored on the node
    DEVOPS_KEYS_PATH = "/root/devops"

    # Dependencies packages to install chef via omnibus
    CHEF_DEPENDENCIES = "curl", "git"

    # Dependencies packages to install berkshelf via ruby gem
    BERKSHELF_DEPENDENCIES = "build-essential", "libxml2-dev", "libxslt-dev"

    # Appd cookbook git address
    APPD_COOKBOOKS = { appd_cookbook: "https://github.com/garnieretienne/appd-cookbook.git" }

    # Appd recipes to install
    APPD_RECIPES = ['appd::app_server']

    # Chef output formatter lib path
    CHEF_FORMATTER = { appd: "#{Appd::ChefInstance::COOKBOOKS_PATH}/appd_cookbook/libraries/appd-chef-formatter.rb" }

    attr_accessor :hostname, :user, :password, :port

    def initialize(options={})
      raise ArgumentError, "No hostname provided" if !options[:hostname]
      options.each{|option, value| self.send("#{option}=", value)}
      @remote = Appd::RemoteHost.new ssh_uri
      @chef = Appd::ChefInstance.new ssh_uri
    end

    # Build a SSH URI (ssh://user:password@hostname:port)
    def ssh_uri
      uri = "ssh://"
      uri += @user if @user
      uri += ":" if @user && @password
      uri += @password if @password
      uri += "@" if @user
      uri += @hostname
      uri += ":#{@port}" if @port
      return uri
    end

    # Configure the hostname on the remote host
    def configure_remote_hostname
      system_name = @hostname.split(/^(\w*)\.*./)[1]
      @remote.name = system_name if @remote.name != system_name
      @remote.fqdn = @hostname if @remote.fqdn != @hostname
    end

    # Update the system on the remote host
    def update_system(&block)
      @remote.system_update do |output|
        yield output
      end
    end

    # Upload the user pub key to the `SYSOPS_KEYS_PATH` on the remote host
    def upload_sysop_key(user, key_path)
      @remote.upload key_path, "#{SYSOPS_KEYS_PATH}/#{user}.pub"
    end

    # Upload the user pub key to the `DEVOPS_KEYS_PATH` on the remote host
    def upload_devop_key(user, key_path)
      @remote.upload key_path, "#{DEVOPS_KEYS_PATH}/#{user}.pub"
    end

    # Install chef, berkshelf and their dependencies on the remote host
    def install_chef
      @remote.install BERKSHELF_DEPENDENCIES + BERKSHELF_DEPENDENCIES
      @chef.install
    end
    
    # Run chef on the remote host and apply `APPD_RECIPES` from `APPD_COOKBOOKS`
    def run_chef(&block)
      @chef.cookbooks = APPD_COOKBOOKS
      @chef.recipes = APPD_RECIPES
      @chef.formatter = CHEF_FORMATTER
      @chef.run do |output|
        yield output
      end
    end

    # TODO
    def close_pending_ssh_connections
    end
  end
end