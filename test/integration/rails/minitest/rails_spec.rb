# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::rails' do

  let(:pushit_path) { ::File.join('', 'opt', 'pushit') }

  let(:pushit_app) { 'rails-example' }

  let(:pushit_app_path) { ::File.join(pushit_path, 'apps', pushit_app) }

  let(:pushit_pid_path) do
    ::File.join(pushit_app_path, 'shared', 'pids', 'upstart.pid')
  end

  let(:upstart_config_path) do
    ::File.join('', 'etc', 'init', "#{pushit_app}.conf")
  end

  let(:database_yaml_path) do
    ::File.join(pushit_app_path, 'current', 'config', 'database.yml')
  end

  let(:dotenv_path) do
    ::File.join(pushit_app_path, 'current', '.env')
  end

  let(:ruby_bin_path) do
    ::File.join(pushit_path, 'rubies', '2.1.1', 'bin')
  end

  let(:pushit_app_log_path) do
    ::File.join(pushit_app_path, 'shared', 'log')
  end

  let(:logrotate_logs_path) do
    ::File.join(pushit_app_log_path, '*.log')
  end

  let(:bundler_binstubs_path) do
    ::File.join(pushit_app_path, 'current', 'bin')
  end

  let(:monit_group) do
    "pushit_#{pushit_app}"
  end

  it 'has created the base pushit directory' do
    assert File.directory?(pushit_path)
  end

  it 'has created a rails app in pushit base' do
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

  it 'has symlinked the .env file' do
    assert ::File.symlink?(dotenv_path)
  end

  it 'has included the ruby bin path in .env' do
    assert ::File.read(dotenv_path).include?(ruby_bin_path)
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
    assert File.directory?(
      ::File.join(bundler_binstubs_path)
    )
  end

  it 'has vendored the bundled gems' do
    assert File.directory?(
      ::File.join(pushit_app_path, 'current', 'vendor', 'bundle', 'ruby', '2.1.0', 'gems')
    )
  end

  it 'has created a pids directory' do
    assert File.directory?(
      ::File.join(pushit_app_path, 'shared', 'pids')
    )
  end

  it 'has created a service config' do
    assert File.file?(
      ::File.join('', 'etc', 'init', "#{pushit_app}.conf")
    )
  end

  it 'starts the rails app service after converge' do
    assert system(
      "service #{pushit_app} status | grep -e 'start/running'"
    )
  end

  it 'manages the application logs with logrotate' do
    assert ::File.read(
      "/etc/logrotate.d/#{pushit_app}"
    ).include?(logrotate_logs_path)
  end

  it 'the monit config includes the app group' do
    assert ::File.read(
      ::File.join('', 'etc', 'monit', 'conf.d', "#{pushit_app}.monitrc")
    ).include?(monit_group)
  end

  it 'uses monit to monitor the unicorn workers' do
    # skip if we're not done initializing
    if `sudo monit status`.match(/Process '#{pushit_app}'\r?\n\s+status\s+(\w+).*\n/).captures[0] == 'Initializing'
      skip("#{pushit_app} still initializing")
    end

    output = `sudo monit status`.match(/^Process '#{pushit_app}'\s+status\s+.*\n\s+monitoring status\s+(.*)\r?\n/)
    assert((!output.nil? && output.captures.first == 'Monitored'), output)
  end

  it 'monit knows if the unicorn workers are up' do
    # skip if we're not done initializing
    if `sudo monit status`.match(/Process '#{pushit_app}'\r?\n\s+status\s+(\w+).*\n/).captures[0] == 'Initializing'
      skip("#{pushit_app} still initializing")
    end

    output = `sudo monit status`.match(/^Process '#{pushit_app}'\s+status\s+(.*)\r?\n\s+monitoring status\s+Monitored/)
    assert((!output.nil? && output.captures.first == 'Running'), output)
  end
end
