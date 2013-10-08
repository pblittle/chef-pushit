# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::user' do

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

  let(:pushit_user_2) { 'foo' }
  let(:pushit_group_2) { 'bar' }
  let(:pushit_home_2) { '/home/foo' }

  it 'creates a 2nd deploy group' do
    assert Etc.getgrnam(pushit_group_2)
  end

  it 'creates a 2nd deploy user' do
    assert Etc.getpwnam(pushit_user_2)
  end

  it 'creates a 2nd home directory in pushit base' do
    assert Etc.getpwnam(pushit_user_2).dir == pushit_home_2
  end

  it 'has created the 2nd deploy user in /home/foo' do
    assert File.read('/etc/passwd').include?(pushit_home_2)
  end

  it 'has created a \.ssh directory for the 2nd deploy user' do
    assert File.directory?(::File.join(pushit_home_2, '.ssh'))
  end

  it 'has granted deploy 2 ownership of the /.ssh directory' do
    assert File.stat(
      ::File.join(pushit_home_2, '.ssh')
    ).uid == Etc.getpwnam(pushit_user_2).uid
  end

  it 'has created a deploy key for the example app' do
    assert File.read(
      ::File.join(pushit_home_2, '.ssh', 'id_rsa_rails-example')
    ).include?('rails-example-deploy-key')
  end

  it 'has created a deploy wrapper for the example app' do
    assert File.read(
      ::File.join(pushit_home_2, '.ssh', 'id_rsa_rails-example_deploy_wrapper.sh')
    ).include?('id_rsa_rails-example')
  end
end
