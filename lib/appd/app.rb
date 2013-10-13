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
      return @api.create(@name).to_s
    end

    # Get all config vars for the app
    def list_config
      configs = store :get, 'configs'
      (configs.error?) ? 'No config vars set yet.' : configs.to_s
    end

    # Set a config var for the app
    def set_config(key, value)
      return store(:set, "configs/#{key}", value).to_s
    end

    # Unset a config var from the app
    def unset_config(key)
      store :delete, "configs/#{key}"
    end

    # Build a new release of the app, run it and route it
    def release
      # configs = store(:get, 'configs').gsub("\n", " ")
      
      # TODO: if error, user need to deploy code first (nothing to deploy) => use a special exit code 
      # when code is not pushed or only deploy if app has a correct build
      # version = @api.release @name, configs
      # backend = @api.run @name, :web, version
      # @api.route @name, backend
      # return version
    end

    private

    # Link to the store API, namespace all command with the application name
    def store(cmd, *args)
      @api.store "#{cmd} #{@name}/#{args.join(' ')}"
    end
  end
end