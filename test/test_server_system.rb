require 'test/unit'
require 'byebug' # For debugging purpose
require 'appd/server/system'

class ServerSystemTest < Test::Unit::TestCase

  # Setup an accessible SSH server using env variables to test this class
  # @example
  #   export APPD_TEST_SSH_URI=ssh://user:password@192.168.1.10
  def setup
    @ssh_uri = ENV['APPD_TEST_SSH_URI'] || "ssh://vagrant:vagrant@localhost:2222"
  end

  def test_system_hostname_getter
    host = Appd::Server::System.new @ssh_uri
    assert_not_nil host.hostname
  end

  def test_system_hostname_setter
    host = Appd::Server::System.new @ssh_uri
    new_hostname = "a#{Time.now.to_i.to_s}"
    host.hostname = new_hostname
    assert_equal new_hostname, host.hostname
  end

  def test_system_fqdn_getter
    host = Appd::Server::System.new @ssh_uri
    assert_not_nil host.fqdn
  end

  def test_system_fqdn_setter
    host = Appd::Server::System.new @ssh_uri
    new_fqdn = "#{host.hostname}.a#{Time.now.to_i.to_s}.tld"
    host.fqdn = new_fqdn
    assert_equal new_fqdn, host.fqdn
  end

  def test_system_ip_getter
    host = Appd::Server::System.new @ssh_uri
    assert_not_nil host.ip
  end

  def test_system_update
    host = Appd::Server::System.new @ssh_uri
    assert_nothing_raised do
      host.update
    end
  end

  def test_admin_key_upload
    host = Appd::Server::System.new @ssh_uri
    assert host.upload_admin_key(ENV['USER'], "#{ENV['HOME']}/.ssh/id_rsa.pub")
    assert host.ssh.exec?("ls /root/admin_keys/#{ENV['USER']}.pub", sudo: true)
  end

  def test_system_package_install
    host = Appd::Server::System.new @ssh_uri
    host.install :htop
    assert host.ssh.exec?("which htop")
    host.uninstall :htop
    assert !host.ssh.exec?("which htop")
  end
end