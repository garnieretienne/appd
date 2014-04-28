require 'json'

module Appd

  class ChefInstance
    include Appd::SSHClient

    attr_accessor :cookbooks, :recipes, :formatter

    # Location where various chef-related files are stored
    CHEF_VAR_PATH = "/var/lib/chef"

    # Location where cookbook are downloaded
    COOKBOOKS_PATH = "#{CHEF_VAR_PATH}/cookbooks"

    # Location where cookbooks and their dependencies are vendored
    VENDOR_COOKBOOKS_PATH = "#{CHEF_VAR_PATH}/site-cookbooks"

    # Install Opscode Chef and Riot Berkshelf on the remote host
    def install
      ssh.exec! "curl -O https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/12.04/x86_64/chefdk_0.0.1-1_amd64.deb"
      ssh.exec! "dpkg --install chefdk_0.0.1-1_amd64.deb", sudo: true
      ssh.exec! "rm chefdk_0.0.1-1_amd64.deb", sudo: true
    end

    # Run chef solo with the configured cookbooks recipes
    # Solo and node config files are generated at runtime
    # If a block is given, the output is sent in live
    # Use a formatter lib if defined
    def run(&block)
      register_cookbooks
      generate_solo_config && generate_node_config
      ssh.exec "chef-solo --config #{CHEF_VAR_PATH}/solo.rb --json-attributes #{CHEF_VAR_PATH}/node.json #{"--force-formatter --log_level error --format #{@formatter.first[0]}" if @formatter && @formatter.any?}", sudo: true do |ch, stream, data, cmd|
        yield data
      end
    end

    private

    # Install or update all cookbooks on the remote host and install their dependencies
    def register_cookbooks
      @cookbooks.each do |name, git_address|
        if ssh.exec? "ls #{COOKBOOKS_PATH}/#{name}"
          ssh.exec! "cd #{COOKBOOKS_PATH}/#{name}; git pull origin master", sudo: true
        else
          ssh.exec! "git clone #{git_address} #{COOKBOOKS_PATH}/#{name}", sudo: true
        end
        ssh.exec! "berks vendored #{VENDOR_COOKBOOKS_PATH} --berksfile #{COOKBOOKS_PATH}/#{name}/Berksfile"
      end
    end

    # Generate the "solo.rb" config file for Chef
    # Include a formatter lib if defined
    def generate_solo_config
      ssh.write "#{CHEF_VAR_PATH}/solo.rb", sudo: true do |file|
        file << "require '#{@formatter.first[1]}'" if @formatter && @formatter.any?
        file << "cookbook_path ['#{VENDOR_COOKBOOKS_PATH}']"
      end
    end

    # Generate the "node.json" config file for Chef
    def generate_node_config
      run_list = { run_list: @recipes.map{|name| "recipe[#{name}]"} }
      ssh.write "#{CHEF_VAR_PATH}/node.json", content: JSON.generate(run_list), sudo: true
    end
  end
end