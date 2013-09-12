# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::user' do

  let(:home_path) { '/opt/pushit' }

  let(:pushit_user) { 'deploy' }
  let(:pushit_group) { 'deploy' }

  it 'creates a deploy group' do
    assert Etc.getgrnam(pushit_user).name == pushit_user
  end

  it 'creates a deploy user' do
    assert Etc.getpwnam(pushit_user).name == pushit_group
  end

  it 'creates a deploy user in the home path' do
    assert Etc.getpwnam(pushit_user).name == pushit_group
  end

  it 'creates a home directory in pushit base' do
    assert Etc.getpwnam(pushit_user).dir == home_path
  end

  it 'has created the deploy user in pushit base' do
    assert File.read('/etc/passwd').include?(home_path)
  end

  it 'has created a \.ssh directory' do
    assert File.directory?(::File.join(home_path, '.ssh'))
  end

  it 'has granted deploy ownership of the /.ssh directory' do
    assert File.stat(
      ::File.join(home_path, '.ssh')
    ).uid == Etc.getpwnam(pushit_user).uid
  end

  it 'has created a deploy key for the example app' do
    assert File.read(
      ::File.join(home_path, '.ssh', 'id_rsa_rails-example')
    ).include?('rails-example-deploy-key')
  end

  it 'has created a deploy wrapper for the example app' do
    assert File.read(
      ::File.join(home_path, '.ssh', 'id_rsa_rails-example_deploy_wrapper.sh')
    ).include?('id_rsa_rails-example')
  end
end
