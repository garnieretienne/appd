require 'appd/error'
require 'net/ssh'
require 'net/scp'
require 'uri'

module Appd

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
    # Can be used without block, but the connection need to be closed manually
    # 
    # @example
    #   server.connect do
    #     server.exec "whoami"
    #   end
    def connect(&block)
      options = { port: @port }

      if @password then
        options[:password] = @password
      else
        options[:keys] = @key
      end

      if block
        Net::SSH.start @host, @user, options do |ssh|
          @ssh = ssh
          yield ssh
          @ssh = nil
        end
      else
        @ssh = Net::SSH.start @host, @user, options
      end
    end

    # Close the SSH connection if opened
    def disconnect
      @ssh.close if @ssh
      @ssh = nil
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
    # @option options [Boolean] :sudo run the command with sudo if the user is not root
    # @option options [String] :as run the command as the given user (using sudo)
    # @return [Array<String>] the exit status code, stdout, stderr and the executed command (useful for debugging)
    def exec(cmd, options={}, &block)
      raise Appd::Error, "No active connection to the server" if !@ssh
      
      stdout, stderr, exit_status = "", "", nil

      # Ask for user password if not set and modify the command
      if (options[:sudo] && @user != "root") || options[:as]
        cmd = "sudo #{options[:as] ? "-u #{options[:as]} -H -i " : "-s "}<< EOCMD\n#{cmd}\nEOCMD"
      end

      @ssh.open_channel do |channel|       
        channel.exec(cmd) do |ch, success|
          raise Appd::Error, "Couldn't execute command '#{cmd}' on the remote host" unless success

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

    # Exec a command on the server (need to be connected) AND raise an error if the command failed.
    # If an error is raised, it will print the backtrace, the stdout and stderr, the command and its exit status code.
    #
    # @param cmd [String] the command to execute
    # @param options [Hash] the options for the command executions
    # @option options [Boolean] :sudo run the command with sudo if the user is not root
    # @option options [String] :as run the command as the given user (use sudo)
    # @option options [String] :error_message ('The following command exited with an error') the error message to print when an error is raised
    # @return [String] the standart ouput returned by the command
    def exec!(cmd, options={})
      exit_status, stdout, stderr, cmd = exec(cmd, options)
      error_msg = options[:error_msg] || "The following command exited with an error"
      raise Appd::RemoteError.new(stdout, stderr, exit_status, cmd), error_msg if exit_status != 0
      return stdout
    end

    # Exec a command on the remote server and return the exit status
    #
    # @param cmd [String] the command to execute
    # @param options [Hash] the options for the command executions
    # @option options [Boolean] :sudo run the command with sudo if the user is not root
    # @option options [String] :as run the command as the given user (use sudo)
    # @option options [String] :error_message ('The following command exited with an error') the error message to print when an error is raised
    # @return [Boolean] the exit status (`true` means exited with exit code `0`, `false` otherwise)
    def exec?(cmd, options={})
      exit_status, stdout, stderr, cmd = exec(cmd, options)
      return (exit_status == 0)
    end

    # Write content into a file on the remote host
    #
    # @example Hello World
    #   ssh.write "/tmp/hello_world" do |content|
    #     content << "Hello"
    #     content << "World"
    #   end
    #
    # @example No block
    #   ssh.write "/tmp/hello_world", content: "Hello World!"
    #
    # @param path [String] the path of the file on the remote system
    # @param options [Hash] the options for the command executions
    # @option options [String] :content the content to write
    # @option options [Boolean] :sudo run the command with sudo if the user is not root
    # @option options [String] :as run the command as the given user (use sudo)
    # @option options [String] :error_message ('The following command exited with an error') the error message to print when an error is raised
    def write(path, options={}, &block)
      content = options[:content]
      if block
        content = []
        yield content
        content = content.join("\n")
      end
      exec! "cat > '#{path}' <<EOF\n#{content}\nEOF", options
    end

    # Send a local file to the server using scp.
    #
    # @param src [String] local path to the file to send
    # @param dst [String] path where the file will be copied on the server
    # @return [Boolean] is the transfert completed
    def send_file(src, dst)
      uploaded = false
      Net::SCP.start(@host, @user, password: @password, port: @port) do |scp|
        scp.upload! src, dst do |ch, name, sent, total|
          uploaded = true if sent == total
        end
      end
      return uploaded
    end
  end
end