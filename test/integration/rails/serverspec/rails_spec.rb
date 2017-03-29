# encoding: utf-8
require 'spec_helper'

context 'pushit_test::rails' do
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
    expect(file(pushit_path)).to be_directory
  end

  it 'has created a rails app in pushit base' do
    expect(file(pushit_app_path)).to be_directory
  end

  it 'has created an upstart config file' do
    expect(file(upstart_config_path)).to be_file
  end

  it 'has symlinked the current release' do
    expect(file(pushit_app_current_path)).to be_symlink
  end

  it 'has symlinked the .env file' do
    expect(file(dotenv_path)).to be_symlink
  end

  it 'has included the ruby bin path in .env' do
    expect(file(dotenv_path).content).to contain(ruby_bin_path)
  end

  it 'correctly merged multiple config hashes' do
    expect(file(dotenv_path).content).to contain('TEST_VAL_2')
    expect(file(dotenv_path).content).to contain('TEST_VAL_1="true"')
  end

  it 'has created database.yml' do
    expect(file(database_yaml_path)).to be_file
  end

  it 'has symlinked database.yml to current' do
    expect(file(database_yaml_path)).to be_symlink
  end

  it 'has configured the database.yml host attribute' do
    expect(file(database_yaml_path).content).to contain('host: localhost')
  end

  it 'has configured the database.yml options attribute' do
    expect(file(database_yaml_path).content).to contain('foo: bar')
  end

  it 'has created bundler binstubs' do
    expect(file(bundler_binstubs_path)).to be_directory
  end

  it 'has vendored the bundled gems' do
    expect(
      file(::File.join(pushit_app_current_path, 'vendor', 'bundle', 'ruby', '2.1.0', 'gems'))
    ).to be_directory
  end

  it 'has created the shared app directories' do
    pushit_app_shared_dirs.each do |dir|
      expect(file(::File.join(pushit_app_shared_path, dir))).to be_directory
    end
  end

  it 'has created a service config' do
    expect(file(::File.join('', 'etc', 'init', "#{pushit_app}.conf"))).to be_file
  end

  it 'starts the unicorn workers after converge' do
    expect(file(pushit_pid_path)).to be_file
  end

  it 'starts the rails app service after converge' do
    expect(service(pushit_app)).to be_running
  end
end
