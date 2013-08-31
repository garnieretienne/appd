require 'test/unit'
require 'byebug' # For debugging purpose
require 'appd'

class ServerSSHTest < Test::Unit::TestCase

  # Setup an accessible SSH server using env variables to test this class
  # @example
  #   export APPD_TEST_SSH_URI=ssh://user:password@192.168.1.10
  def setup
    @ssh_uri = ENV['APPD_TEST_SSH_URI'] || "ssh://#{ENV['USER']}@127.0.0.1:22"
  end

  def test_remote_instance_creation_with_password
    remote = Appd::Server::SSH.new "ssh://user:password@0.0.0.0:666"
    assert_equal "user", remote.user
    assert_equal "0.0.0.0", remote.host
    assert_equal 666, remote.port
    assert_nil remote.key
  end

  def test_remote_instance_creation_with_key
    remote = Appd::Server::SSH.new "ssh://user@0.0.0.0:666"
    assert_equal "user", remote.user
    assert_equal "0.0.0.0", remote.host
    assert_equal 666, remote.port
    assert_nil remote.password
    assert_equal "#{ENV['HOME']}/.ssh/id_rsa", remote.key
  end

  def test_remote_connection
    remote = Appd::Server::SSH.new @ssh_uri
    assert_nil remote.ssh
    remote.connect do
      assert_not_nil remote.ssh
    end
    assert_nil remote.ssh
  end

  def test_simple_remote_execution
    remote = Appd::Server::SSH.new @ssh_uri
    remote.connect do 
      exit_code, stdout = remote.exec("echo Hello World")
      assert_equal 0, exit_code
      assert_equal "Hello World\n", stdout
    end
  end

  def test_simple_command_execution_as_root
    remote = Appd::Server::SSH.new @ssh_uri
    remote.connect do
      exit_code, stdout = remote.exec("whoami", sudo: true)
      assert_equal 0, exit_code
      assert_equal "root", stdout.chomp
    end
  end

  def test_remote_execution_without_connection_should_raise_error
    remote = Appd::Server::SSH.new @ssh_uri
    assert_raises Appd::Error do
      remote.exec "whoami"
    end
  end
end