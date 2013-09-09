require 'test/unit'
require 'byebug' # For debugging purpose
require 'tempfile'
require 'appd/server/ssh'

class ServerSSHTest < Test::Unit::TestCase

  # Setup an accessible SSH server using env variables to test this class
  # @example
  #   export APPD_TEST_SSH_URI=ssh://user:password@192.168.1.10
  def setup
    @ssh_uri = ENV['APPD_TEST_SSH_URI'] || "ssh://vagrant:vagrant@localhost:2222"
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

  def test_remote_execution_only_outputing_stdout
    remote = Appd::Server::SSH.new @ssh_uri
    remote.connect do 
      assert_equal "foo", remote.exec!("echo foo").chomp
    end
  end

  def test_remote_execution_raising_a_remote_error
    remote = Appd::Server::SSH.new @ssh_uri
    remote.connect do 
      assert_raises Appd::RemoteError do
        remote.exec!("non_existing_command", error_msg: "non existing command!")
      end
    end
  end

  def test_remote_execution_status
    remote = Appd::Server::SSH.new @ssh_uri
    remote.connect do 
      assert remote.exec?("whoami")
      assert !remote.exec?("whoami non_existing_argument")
    end
  end

  def test_remote_connection_without_block
    remote = Appd::Server::SSH.new @ssh_uri
    assert_nil remote.ssh
    remote.connect
    assert_not_nil remote.ssh
    remote.disconnect
    assert_nil remote.ssh
  end

  def test_remote_file_writing
    remote = Appd::Server::SSH.new @ssh_uri
    remote.connect do
      remote.write "/tmp/hello_world", "Hello World"
      assert_equal "Hello World", remote.exec!("cat /tmp/hello_world").chomp
    end
  end

  def test_file_upload
    remote = Appd::Server::SSH.new @ssh_uri
    dst = "/tmp/test-#{Time.now.to_i}"
    Tempfile.open('test_file_upload', '/tmp') do |f|
      remote.connect do
        remote.send_file f.path, dst
        assert remote.exec?("ls #{dst}")
      end
    end
  end
end