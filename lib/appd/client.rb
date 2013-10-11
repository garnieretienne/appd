require "appd/ssh_client"

module Appd
  
  # Client for the Appd SSH API
  class Client
    include Appd::SSHClient

    def missing_method(command, *args)
      if ssh.exec? command
        ssh.exec! "#{command} #{args}"
      else
        raise AppdError, "Unknown command"
      end
    end
  end
end
