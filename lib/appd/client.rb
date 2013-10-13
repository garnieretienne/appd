require "appd/ssh_client"

module Appd
  
  # Client for the Appd SSH API
  class Client
    include Appd::SSHClient

    def method_missing(command, *args)
      if ssh.exec? command
        return Client::CommandResponse.new(*ssh.exec("#{command} #{args.join(' ')}"))
      else
        raise AppdError, "Unknown command"
      end
    end
  end

  # Class representing the response to a SSHClient call
  class Client::CommandResponse

    attr_reader :command

    # Each API command call return an exit_code, the command STDOUT 
    # and STDERR and the executed command
    def initialize(exit_code, stdout, stderr, command)
      @exit_code = exit_code
      @stdout = stdout
      @stderr = stderr
      @command = command
      return self
    end

    # String representation of the command response is STDOUT
    def to_s
      @stdout
    end

    # Return boolean state telling if the command encountered an error
    def error?
      @exit_code != 0
    end

    # Return the command STDERR
    def error
      @stderr
    end
  end
end
