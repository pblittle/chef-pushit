# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::rails' do
  let(:pushit_path) { ::File.join('', 'opt', 'pushit') }

  let(:pushit_app) { 'rails-example' }

  let(:pushit_app_path) { ::File.join(pushit_path, 'apps', pushit_app) }

  let(:pushit_app_current_path) { ::File.join(pushit_app_path, 'current') }

  let(:pushit_app_shared_path) { ::File.join(pushit_app_path, 'shared') }

  let(:pushit_pid_path) do
    ::File.join(pushit_app_shared_path, 'pids', 'upstart.pid')
  end

  let(:upstart_config_path) do
    ::File.join('', 'etc', 'init', "#{pushit_app}.conf")
  end

  let(:database_yaml_path) do
    ::File.join(pushit_app_current_path, 'config', 'database.yml')
  end

  let(:dotenv_path) do
    ::File.join(pushit_app_current_path, '.env')
  end

  let(:ruby_bin_path) do
    ::File.join(pushit_path, 'rubies', '2.1.1', 'bin')
  end

  let(:bundler_binstubs_path) do
    ::File.join(pushit_app_current_path, 'bin')
  end

  let(:pushit_app_shared_dirs) do
    %w( cached-copy config system vendor_bundle log pids sockets )
  end

  it 'has created the base pushit directory' do
    assert File.directory?(pushit_path)
  end

  it 'has created a rails app in pushit base' do
    assert File.directory?(pushit_app_path)
  end

  it 'has created an upstart config file' do
    assert File.file?(upstart_config_path)
  end

  it 'has symlinked the current release' do
    assert File.symlink?(pushit_app_current_path)
  end

  it 'has symlinked the .env file' do
    assert ::File.symlink?(dotenv_path)
  end

  it 'has included the ruby bin path in .env' do
    assert ::File.read(dotenv_path).include?(ruby_bin_path)
  end

  it 'correctly merged multiple config hashes' do
    assert ::File.read(dotenv_path).include?('TEST_VAL_2')
    assert ::File.read(dotenv_path).include?('TEST_VAL_1="true"')
  end

  it 'has created database.yml' do
    assert File.file?(database_yaml_path)
  end

  it 'has symlinked database.yml to current' do
    assert File.symlink?(database_yaml_path)
  end

  it 'has configured the database.yml host attribute' do
    assert ::File.read(
      database_yaml_path
    ).include?('host: localhost')
  end

  it 'has configured the database.yml options attribute' do
    assert ::File.read(
      database_yaml_path
    ).include?('foo: bar')
  end

  it 'has created bundler binstubs' do
    assert File.directory?(bundler_binstubs_path)
  end

  it 'has vendored the bundled gems' do
    assert File.directory?(
      ::File.join(pushit_app_current_path, 'vendor', 'bundle', 'ruby', '2.1.0', 'gems')
    )
  end

  it 'has created the shared app directories' do
    pushit_app_shared_dirs.each do |dir|
      assert File.directory?(::File.join(pushit_app_shared_path, dir))
    end
  end

  it 'has created a service config' do
    assert File.file?(
      ::File.join('', 'etc', 'init', "#{pushit_app}.conf")
    )
  end

  it 'starts the unicorn workers after converge' do
    assert File.file?(pushit_pid_path)
  end

  it 'starts the rails app service after converge' do
    assert system(
      "service #{pushit_app} status | grep -e 'start/running'"
    )
  end
end
