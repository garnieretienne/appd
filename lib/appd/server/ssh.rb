require 'net/ssh'
require 'net/scp'
require 'uri'

module Appd
	module Server

    # Manage SSH connection and remote command execution on an host
    #
    # @example Get the current date from the server
    #   remote = Appd::Server::SSH.new "ssh://user:pass@myserver.tld"
	  #   remote.connect do
	  #     puts "Current date: #{remote.exec!('date').chomp}"
	  #   end
	  class SSH

	  	attr_accessor :host, :port, :user, :password, :key, :ssh

	  	# Define the server to connect to
	  	# If no username is given, the current user name is used
	  	# If no password is given, the current user public key will be used (`~/.ssh/id_rsa.pub`)
	    #
	    # @param ssh_uri [String] complete ssh URI to access the server (ex: ssh://username:password@domain.tld)
	    def initialize(ssh_uri)
	      uri = URI(ssh_uri)
	      @host = uri.host
	      @port = uri.port || 22
	      @user = uri.user || ENV['USER']
	      if uri.password
	        @password = uri.password
	      else
	      	@key = "#{ENV['HOME']}/.ssh/id_rsa"
	      end
	    end

	    # Connect to the server using SSH and cache the connection during the block execution
	    # If no password is memorized, try to connect using the user ssh key (in ~/.ssh/id_rsa)
	    # 
	    # @example
	    #   server.connect do
	    #     server.exec "whoami"
	    #   end
	    def connect
	      options = { port: @port }

	      if @password then
	        options[:password] = @password
	      else
	        options[:keys] = @key
	      end

        Net::SSH.start @host, @user, options do |ssh|
          @ssh = ssh
          yield ssh
          @ssh = nil
        end
	    end

      # Exec a command on the server (need to be connected)
	    # It can also be used using block to work with live data
	    # Support for sudo commands if the user has the right to execute them without password
	    # See: Net::SSH `exec` command (http://net-ssh.github.io/net-ssh/classes/Net/SSH/Connection/Session.html#method-i-exec)
	    #
	    # @example Get the user name
	    #   exit_status, stdout = server.exec "whoami"
	    #   puts "username: #{stdout.chomp}"
	    #
	    # @example Print remote error (using block)
	    #   server.exec "chef-solo" do |channel, stream, data|
	    #     puts data if stream == :stderr
	    #     channel.on_request("exit-status") do |ch, data|
	    #       exit_status = data.read_long
	    #       "Error !" if exit_status != 0
	    #     end
	    #   end
	    #   
	    # @param cmd [String] the command to execute
	    # @param options [Hash] the options for the command executions
	    # @option options [Boolean] :sudo run the command with sudo
	    # @option options [String] :as run the command as the given user (using sudo)
	    # @return [Array<String>] the exit status code, stdout, stderr and the executed command (useful for debugging)
	    def exec(cmd, options={}, &block)
	      raise Chaos::Error, "No active connection to the server" if !@ssh
	      
	      stdout, stderr, exit_status = "", "", nil

	      # Ask for user password if not set and modify the command
	      if options[:sudo] || options[:as]
	        cmd = "sudo #{"-u #{options[:as]} -H -i " if options[:as]}-S bash << EOCMD\n#{cmd}\nEOCMD"
	      end

	      @ssh.open_channel do |channel|       
	        channel.exec(cmd) do |ch, success|
	          raise Chaos::Error, "Couldn't execute command '#{cmd}' on the remote host" unless success

	          channel.on_data do |ch, data|
	            block.call(ch, :stdout, data) if block
	            stdout << data
	          end

	          channel.on_extended_data do |ch, type, data|
	            block.call(ch, :stderr, data) if block
	            stderr << data
	          end

	          channel.on_request("exit-status") do |ch, data|
	            exit_status = data.read_long
	          end
	        end
	      end

	      @ssh.loop
	      return exit_status, stdout, stderr, cmd
	    end
	  end
	end
end