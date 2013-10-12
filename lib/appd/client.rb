require "appd/ssh_client"

module Appd
  
  # Client for the Appd SSH API
  class Client
    include Appd::SSHClient

    def method_missing(command, *args)
      if ssh.exec? command
        ssh.exec! "#{command} #{args.join(' ')}"
      else
        raise AppdError, "Unknown command"
      end
    end
  end
end
