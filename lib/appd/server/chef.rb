require 'json'

module Appd
	module Server
		
		class Chef

			CHEF_REPO_URI = "https://github.com/garnieretienne/appd-chef-repo.git"
			CHEF_REPO_PATH = "/var/lib/appd/chef"

      def initialize(ssh)
      	@ssh = ssh
      	@cookbook_path = ["#{CHEF_REPO_PATH}/cookbooks"]
      	@role_path     = "#{CHEF_REPO_PATH}/roles"
      	@roles = ['app_server']
      end

      # Assume chef is started for the first time and root access
      def init
        clone_chef_repository
      end

      # Run chef and serve the output
      def run(&block)
      	update_chef_repository
      	generate_solo_config
      	generate_node_config
      	@ssh.exec "chef-solo --config /tmp/solo.rb --json-attributes /tmp/node.json --force-formatter --log_level error" do |ch, stream, data, cmd|
          yield data
        end
      end

      private

      # Clone the chef repository, delete the folder first if exist
      def clone_chef_repository
      	@ssh.exec! "rm -rf #{CHEF_REPO_PATH}"
        @ssh.exec! "git clone #{CHEF_REPO_URI} #{CHEF_REPO_PATH}"
      end

      def update_chef_repository
      	@ssh.exec! "cd #{CHEF_REPO_PATH}; git pull origin master"
      end

      def generate_solo_config
        @ssh.write "/tmp/solo.rb" do |file|
        	file << "cookbook_path #{@cookbook_path}"
        	file << "role_path '#{@role_path}'"
        end
      end

      def generate_node_config
      	run_list = { run_list: @roles.map{|name| "role[#{name}]"} }
      	@ssh.write "/tmp/node.json", JSON.generate(run_list)
      end
    end
	end
end