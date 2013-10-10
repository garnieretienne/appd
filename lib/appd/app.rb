require 'appd/helpers'
require 'appd/server/system'

module Appd
  
  class App
    include Appd::Helpers

    APPD_USER = :appd

    def initialize(options)
      @name = options[:name]
      @server = Appd::Server::System.new options[:node]
    end

    def create
      display_ "Creating app '#{@name}' on '#{@server}'", :topic

      display_ "Create git repository..." do
        @server.ssh.exec! "create #{@name}"
      end
    end

    def list_config
      display_ "Config vars for '#{@name}' on '@server'", :topic

      exit_code, configs = @server.ssh.exec "store get #{@name}/configs"
      if exit_code == 0
        display_ configs
      else
        display_ "no configs set yet"
      end
    end

    def set_config(key, value)
      display_ "Setting config vars for '#{@name}' on '@server'", :topic
      
      display_ "set #{key}..." do
        @server.ssh.exec! "store set #{@name}/configs/#{key} #{value}"
      end

      release
    end

    def unset_config(key)
      @server.ssh.exec! "store delete #{@name}/configs/#{key}"
      list_config
    end

    def release
      display_ "restarting app..." do
        version = @server.ssh.exec! "release #{@name} #{read_config}"
        @server.ssh.exec! "run #{@name} web"
        version
      end
    end

    private

    def read_config
      @server.ssh.exec!("store get #{@name}/configs").gsub(/\n/, " ")
    end
  end
end