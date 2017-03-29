# encoding: utf-8
require 'spec_helper'

context 'pushit_test::user' do
  context 'default pushit user' do
    let(:pushit_user) { 'deploy' }
    let(:pushit_group) { 'deploy' }
    let(:pushit_home) { '/opt/pushit' }

    it 'creates a deploy group' do
      expect(group(pushit_group)).to exist
    end

    it 'creates a deploy user' do
      expect(user(pushit_user)).to exist
      expect(user(pushit_user)).to belong_to_primary_group(pushit_group)
    end

    it 'creates a home directory in pushit base' do
      expect(user(pushit_user)).to have_home_directory(pushit_home)
      expect(file(pushit_home)).to be_directory
    end

    it 'does not create a password for the deploy user' do
      expect(user(pushit_user).encrypted_password).to match(/^.{0,2}$/)
    end

    it 'has created a \.ssh directory for the deploy user' do
      expect(file(::File.join(pushit_home, '.ssh'))).to be_directory
    end

    it 'has granted deploy ownership of the /.ssh directory' do
      expect(file(::File.join(pushit_home, '.ssh'))).to be_owned_by(pushit_user)
    end

    it 'has created a deploy key for the example app' do
      expect(file(::File.join(pushit_home, '.ssh', 'id_rsa_rails-example')).content
            ).to contain('rails-example-deploy-key')
    end

    it 'has created a deploy wrapper for the example app' do
      expect(file(::File.join(pushit_home, '.ssh', 'id_rsa_rails-example_deploy_wrapper.sh')).content
            ).to contain('id_rsa_rails-example')
    end

    it 'has created a private rsa key' do
      expect(file(::File.join(pushit_home, '.ssh', 'id_rsa')).content).to contain('-----BEGIN RSA PRIVATE KEY-----')
    end

    it 'has created a public rsa key' do
      expect(file(::File.join(pushit_home, '.ssh', 'id_rsa.pub')).content).to contain('ssh-rsa')
    end

    it 'has created authorized_users' do
      expect(file(::File.join(pushit_home, '.ssh', 'authorized_keys')).content).to contain('ssh-rsa == foo')
    end
  end

  context 'custom pushit user' do
    let(:pushit_user) { 'foo' }
    let(:pushit_group) { 'foo' }
    let(:pushit_home) { '/home/foo' }

    it 'creates a deploy group' do
      expect(group(pushit_group)).to exist
    end

    it 'creates a deploy user' do
      expect(user(pushit_user)).to exist
      expect(user(pushit_user)).to belong_to_primary_group(pushit_group)
    end

    it 'creates a home directory in pushit base' do
      expect(user(pushit_user)).to have_home_directory(pushit_home)
      expect(file(pushit_home)).to be_directory
    end

    it 'has created a \.ssh directory for the deploy user' do
      expect(file(::File.join(pushit_home, '.ssh'))).to be_directory
    end

    it 'has granted deploy ownership of the /.ssh directory' do
      expect(file(::File.join(pushit_home, '.ssh'))).to be_owned_by(pushit_user)
    end

    it 'has created a deploy key for the example app' do
      expect(file(::File.join(pushit_home, '.ssh', 'id_rsa_rails-example')).content
            ).to contain('rails-example-deploy-key')
    end

    it 'has created a deploy wrapper for the example app' do
      expect(file(::File.join(pushit_home, '.ssh', 'id_rsa_rails-example_deploy_wrapper.sh')).content
            ).to contain('id_rsa_rails-example')
    end

    it 'has created a private dsa key' do
      expect(file(::File.join(pushit_home, '.ssh', 'id_dsa')).content).to contain('-----BEGIN DSA PRIVATE KEY-----')
    end

    it 'has created a public dsa key' do
      expect(file(::File.join(pushit_home, '.ssh', 'id_dsa.pub')).content).to contain('ssh-dsa')
    end

    it 'notifies resources that subscribe to it' do
      expect(file('/tmp/kitchen/cache/pushit_user_notification_flag')).to be_file
    end
  end
end
