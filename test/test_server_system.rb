require 'test/unit'
require 'byebug' # For debugging purpose
require 'appd/server/system'

class ServerSystemTest < Test::Unit::TestCase

  # Setup an accessible SSH server using env variables to test this class
  # @example
  #   export APPD_TEST_SSH_URI=ssh://user:password@192.168.1.10
  def setup
    @ssh_uri = ENV['APPD_TEST_SSH_URI'] || "ssh://#{ENV['USER']}@127.0.0.1:22"
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
end