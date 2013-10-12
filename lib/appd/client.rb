require "appd/ssh_client"

module Appd
  
  # Client for the Appd SSH API
  class Client
    include Appd::SSHClient

    def method_missing(command, *args)
      if ssh.exec? command
        exit_code, stdout, stderr = ssh.exec "#{command} #{args.join(' ')}"
        # puts "#{exit_code}: #{stderr}"
        return stdout
      else
        raise AppdError, "Unknown command"
      end
    end
  end
end
