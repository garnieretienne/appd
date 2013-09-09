require 'thor'

module Appd

  # The Appd CLI
  class CLI < Thor
    
    desc "bootstrap SSH_URI", "Bootstrap a server with a root SSH access"
    def bootstrap(ssh_uri)
      node = Appd::Node.new ssh_uri
      node.bootstrap
    end
  end
end