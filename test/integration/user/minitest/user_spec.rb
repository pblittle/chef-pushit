# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::user' do

  describe 'default pushit user' do

    let(:pushit_user) { 'deploy' }
    let(:pushit_group) { 'deploy' }
    let(:pushit_home) { '/opt/pushit' }

    it 'creates a deploy group' do
      assert Etc.getgrnam(pushit_group).name == pushit_group
    end

    it 'creates a deploy user' do
      assert Etc.getpwnam(pushit_user).name == pushit_user
    end

    it 'creates a home directory in pushit base' do
      assert Etc.getpwnam(pushit_user).dir == pushit_home
    end

    it 'does not create a password for the deploy user' do
      assert File.read(
        ::File.join('', 'etc', 'shadow')
      ).match(/^deploy:[*|!]:/)
    end

    it 'has created the deploy user in pushit base' do
      assert File.read('/etc/passwd').include?(pushit_home)
    end

    it 'has created a \.ssh directory for the deploy user' do
      assert File.directory?(::File.join(pushit_home, '.ssh'))
    end

    it 'has granted deploy ownership of the /.ssh directory' do
      assert File.stat(
        ::File.join(pushit_home, '.ssh')
      ).uid == Etc.getpwnam(pushit_user).uid
    end

    it 'has created a deploy key for the example app' do
      assert File.read(
        ::File.join(pushit_home, '.ssh', 'id_rsa_rails-example')
      ).include?('rails-example-deploy-key')
    end

    it 'has created a deploy wrapper for the example app' do
      assert File.read(
        ::File.join(pushit_home, '.ssh', 'id_rsa_rails-example_deploy_wrapper.sh')
      ).include?('id_rsa_rails-example')
    end

    it 'has created a private rsa key' do
      assert File.read(
        ::File.join(pushit_home, '.ssh', 'id_rsa')
      ).include?('-----BEGIN RSA PRIVATE KEY-----')
    end

    it 'has created a public rsa key' do
      assert File.read(
        ::File.join(pushit_home, '.ssh', 'id_rsa.pub')
      ).include?('ssh-rsa')
    end

    it 'has created authorized_users' do
      assert File.read(
        ::File.join(pushit_home, '.ssh', 'authorized_keys')
      ).include?('ssh-rsa == foo')
    end
  end

  describe 'custom pushit user' do

    let(:pushit_user) { 'foo' }
    let(:pushit_group) { 'foo' }
    let(:pushit_home) { '/home/foo' }

    it 'creates a 2nd deploy group' do
      assert Etc.getgrnam(pushit_group)
    end

    it 'creates a 2nd deploy user' do
      assert Etc.getpwnam(pushit_user)
    end

    it 'creates a 2nd home directory in pushit base' do
      assert Etc.getpwnam(pushit_user).dir == pushit_home
    end

    it 'creates a password for the 2nd deploy user' do
      refute File.read(
        ::File.join('', 'etc', 'shadow')
      ).match(/^foo:[*|!]:/)
    end

    it 'has created the 2nd deploy user in /opt/pushit' do
      assert File.read('/etc/passwd').include?(pushit_home)
    end

    it 'has created a \.ssh directory for the 2nd deploy user' do
      assert File.directory?(::File.join(pushit_home, '.ssh'))
    end

    it 'has granted deploy 2 ownership of the /.ssh directory' do
      assert File.stat(
        ::File.join(pushit_home, '.ssh')
      ).uid == Etc.getpwnam(pushit_user).uid
    end

    it 'has created a deploy key for the example app' do
      assert File.read(
        ::File.join(pushit_home, '.ssh', 'id_rsa_rails-example')
      ).include?('rails-example-deploy-key')
    end

    it 'has created a deploy wrapper for the example app' do
      assert File.read(
        ::File.join(pushit_home, '.ssh', 'id_rsa_rails-example_deploy_wrapper.sh')
      ).include?('id_rsa_rails-example')
    end

    it 'has created a private dsa key' do
      assert File.read(
        ::File.join(pushit_home, '.ssh', 'id_dsa')
      ).include?('-----BEGIN DSA PRIVATE KEY-----')
    end

    it 'has created a public dsa key' do
      assert File.read(
        ::File.join(pushit_home, '.ssh', 'id_dsa.pub')
      ).include?('ssh-dsa')
    end

    it 'notifies resources that subscribe to it' do
      assert(::File.file?("/tmp/kitchen/cache/pushit_user_notification_flag"),
        "/tmp/kitchen/cache/pushit_user_notification_flag does not exist"
      )
    end
  end
end
