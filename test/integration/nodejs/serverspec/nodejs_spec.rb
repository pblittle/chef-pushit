# encoding: utf-8
require 'spec_helper'

context 'pushit_test::nodejs' do
  let(:pushit_path) { ::File.join('', 'opt', 'pushit') }

  let(:pushit_app) { 'nodejs-example' }

  let(:pushit_app_path) { ::File.join(pushit_path, 'apps', pushit_app) }

  let(:pushit_pid_path) do
    ::File.join(pushit_app_path, 'shared', 'pids', 'upstart.pid')
  end

  let(:pushit_app_log_path) do
    ::File.join(pushit_app_path, 'shared', 'log')
  end

  let(:upstart_config_path) do
    ::File.join('', 'etc', 'init', "#{pushit_app}.conf")
  end

  it 'has created the base pushit directory' do
    expect(file(pushit_path)).to be_directory
  end

  it 'has created a nodejs app in pushit base' do
    expect(file(pushit_app_path)).to be_directory
  end

  it 'has created a log directory' do
    skip 'currently upstart is logging to /var/log/upstart'
    expect(file(pushit_app_log_path)).to be_directory
  end

  it 'has created an upstart config file' do
    expect(file(upstart_config_path)).to be_file
  end

  it 'has symlinked the current release' do
    expect(file(::File.join(pushit_app_path, 'current'))).to be_symlink
  end

  it 'has created a pids directory' do
    skip 'nodejs apps are not writing a pid currently'
    expect(file(::File.join(pushit_app_path, 'shared', 'pids'))).to be_directory
  end

  it 'has symlinked the .env file' do
    expect(file(::File.join(pushit_app_path, 'current', '.env'))).to be_symlink
  end

  it 'has created a service config' do
    expect(file(::File.join('', 'etc', 'init', "#{pushit_app}.conf"))).to be_file
  end

  it 'starts the nodejs app service after converge' do
    expect(service(pushit_app)).to be_running
  end
end
