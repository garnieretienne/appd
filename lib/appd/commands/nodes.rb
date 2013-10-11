require 'thor'
require "appd/helpers"
require "appd/node"
require "appd/app"

module Appd

  module Commands

    class Nodes < Thor
      include Appd::Helpers
      
      desc "bootstrap SSH_URI", "Bootstrap a server using a root SSH access"
      def bootstrap(ssh_uri)

        uri = URI.parse ssh_uri
        node = Appd::Node.new(
          hostname: uri.host,
          user: uri.user || false,
          password: uri.password || false,
          port: uri.port || false
        )

        display_ "Bootstrapping #{node.hostname}", :topic

        display_ "Updating the system", :topic

        node.update_system do |output|
          display_ output, :live
        end

        display_ "Configuring the system", :topic

        display_ "configure hostname..." do
          node.configure_remote_hostname
        end

        display_ "upload a sysop key for user '#{ENV['USER']}'..." do
          node.upload_sysop_key(ENV["USER"], "#{ENV['HOME']}/.ssh/id_rsa.pub")
        end

        display_ "upload a devop key for user '#{ENV['USER']}'..." do
          node.upload_devop_key(ENV["USER"], "#{ENV['HOME']}/.ssh/id_rsa.pub")
        end

        display_ "Installing and running Chef", :topic

        display_ "install chef on the remote host..." do
          node.install_chef
          'done'
        end

        node.run_chef do |output|
          display_ output, :live
        end

        display_ "Done.", :topic
        display_ "Sysop: ssh #{ENV['USER']}@#{node.hostname}"
        display_ "Devop: ssh #{Appd::App::APPD_USER}@#{node.hostname}"

        # TODO
        # node.close_pending_ssh_connections
      end

      desc "update SSH_URI", "Update a server (system and services)"
      option :node, required: true
      def update
        node = Appd::Node.new(hostname: options[:node])

        display_ "Updating #{node.hostname}", :topic

        display_ "Updating the system", :topic

        node.update_system do |output|
          display_ output, :live
        end

        display_ "Running Chef", :topic

        node.run_chef do |output|
          display_ output, :live
        end

        display_ "Done.", :topic

        # TODO
        # node.close_pending_ssh_connections
      end
    end
  end
end