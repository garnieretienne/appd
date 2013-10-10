require 'thor'
require 'appd/node'

module Appd

  module Commands

    class Node < Thor
      
      desc "bootstrap SSH_URI", "Bootstrap a server with a root SSH access"
      def bootstrap(ssh_uri)
        node = Appd::Node.new ssh_uri
        node.set_hostname_and_domain_name
        node.system_update
        node.install_chef
        node.upload_local_user_key
        node.run_chef
      end

      desc "update SSH_URI", "Update a server (system and services)"
      def update(ssh_uri)
        node = Appd::Node.new ssh_uri
        node.system_update
        node.run_chef
      end
    end
  end
end