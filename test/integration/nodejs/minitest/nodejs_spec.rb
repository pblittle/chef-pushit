# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::nodejs' do

  let(:pushit_path) { ::File.join('', 'opt', 'pushit') }

  let(:pushit_app) { 'nodejs-example' }

  let(:pushit_app_path) { ::File.join(pushit_path, 'apps', pushit_app) }

  let(:pushit_pid_path) do
    ::File.join(pushit_app_path, 'shared', 'pids', 'upstart.pid')
  end

  let(:pushit_app_log_path) do
    ::File.join(pushit_app_path, 'shared', 'log')
  end

  let(:logrotate_logs_path) do
    ::File.join(pushit_app_log_path, '*.log')
  end

  let(:upstart_config_path) do
    ::File.join('', 'etc', 'init', "#{pushit_app}.conf")
  end

  it 'has created the base pushit directory' do
    assert File.directory?(pushit_path)
  end

  it 'has created a nodejs app in pushit base' do
    assert File.directory?(pushit_app_path)
  end

  it 'has created a log directory' do
    assert File.directory?(pushit_app_log_path)
  end

  it 'has created an upstart config file' do
    assert File.file?(upstart_config_path)
  end

  it 'has symlinked the current release' do
    assert File.symlink?(
      ::File.join(pushit_app_path, 'current')
    )
  end

  it 'has created a pids directory' do
    assert File.directory?(
      ::File.join(pushit_app_path, 'shared', 'pids')
    )
  end

  it 'has symlinked the current directory' do
    assert File.symlink?(
      ::File.join(pushit_app_path, 'current')
    )
  end

  it 'has symlinked the .env file' do
    assert File.symlink?(
      ::File.join(pushit_app_path, 'current', '.env')
    )
  end

  it 'has created a service config' do
    assert File.file?(
      ::File.join('', 'etc', 'init', "#{pushit_app}.conf")
    )
  end

  it 'starts the nodejs app service after converge' do
    assert system(
      "service #{pushit_app} status | grep -e 'start/running'"
    )
  end

  it 'manages the application logs with logrotate' do
    assert ::File.read(
      "/etc/logrotate.d/#{pushit_app}"
    ).include?(logrotate_logs_path)
  end
end
