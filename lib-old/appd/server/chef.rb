require 'json'

module Appd
  module Server
    
    class Chef
      APPD_VAR_PATH = "/var/lib/appd"
      CHEF_RUBY_INSTANCE_BASE = "/opt/chef/embedded"

      APPD_COOKBOOK_URI = "https://github.com/garnieretienne/appd-cookbook.git"
      APPD_COOKBOOK_PATH = "#{APPD_VAR_PATH}/appd-cookbook"

      def initialize(ssh)
        @ssh = ssh
        @cookbook_path = ["#{APPD_VAR_PATH}/cookbooks"]
        @recipes = ['appd::app_server']
      end

      # Assume chef is started for the first time and root access
      # Clone the appd cookbook repository and download dependencies to run it
      def init
        clone_appd_cookbook
        chef_gem "install berkshelf"
      end

      # Run chef and serve the output
      def run(&block)
        update_appd_cookbook
        generate_solo_config
        generate_node_config
        @ssh.exec "chef-solo --config /tmp/solo.rb --json-attributes /tmp/node.json --force-formatter --log_level error --format appd", sudo: true do |ch, stream, data, cmd|
          yield data
        end
      end

      private

      # Install a gem only for the instance of Ruby that is dedicated to 'chef-solo'
      def chef_gem(args)
        @ssh.exec! "#{CHEF_RUBY_INSTANCE_BASE}/bin/gem #{args}", sudo: true
      end

      # execute a gem binary installed for the instance of Ruby that is dedicated to 'chef-solo'
      def chef_exec(cmd)
        @ssh.exec! "#{CHEF_RUBY_INSTANCE_BASE}/bin/#{cmd}", sudo: true
      end

      # Clone the appd cookbook repository, delete the folder first if exist
      def clone_appd_cookbook
        @ssh.exec! "rm -rf #{APPD_COOKBOOK_PATH}", sudo: true
        @ssh.exec! "git clone #{APPD_COOKBOOK_URI} #{APPD_COOKBOOK_PATH}", sudo: true
      end

      # Pull the last change from the appd cookbook repository
      # And install cookbook dependencies
      def update_appd_cookbook
        @ssh.exec! "cd #{APPD_COOKBOOK_PATH}; git pull origin master", sudo: true
        chef_exec "berks install --path #{@cookbook_path.first} --berksfile #{APPD_COOKBOOK_PATH}/Berksfile"
      end

      # Generate the "solo.rb" config file for Chef
      def generate_solo_config
        @ssh.write "/tmp/solo.rb", sudo: true do |file|
          file << "require '#{APPD_COOKBOOK_PATH}/libraries/appd-chef-formatter.rb'"
          file << "cookbook_path #{@cookbook_path}"
        end
      end

      # Generate the "node.json" config file for Chef
      def generate_node_config
        run_list = { run_list: @recipes.map{|name| "recipe[#{name}]"} }
        @ssh.write "/tmp/node.json", content: JSON.generate(run_list), sudo: true
      end
    end
	end
end