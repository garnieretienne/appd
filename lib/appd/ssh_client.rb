require 'appd/ssh'

module Appd

  module SSHClient

    def initialize(ssh_uri)
      @ssh = Appd::SSH.new ssh_uri
    end

    # Cache the SSH connection to the remote host
    def ssh
      @connection ||= @ssh.connect
      return @ssh
    end
  end
end