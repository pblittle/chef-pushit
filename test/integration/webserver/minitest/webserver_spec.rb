# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::webserver' do

  let(:pushit_path) { ::File.join('', 'opt', 'pushit') }

  let(:webserver_path) { ::File.join(pushit_path, 'nginx') }

  let(:webserver_config) { ::File.join(webserver_path, 'nginx.conf') }

  let(:webserver_log_path) { ::File.join(webserver_path, 'log') }

  let(:webserver_access_log) { ::File.join(webserver_log_path, 'access.log') }

  let(:webserver_error_log) { ::File.join(webserver_log_path, 'error.log') }

  it 'has created the base pushit directory' do
    assert ::File.directory?(pushit_path)
  end

  it 'has created the nginx install directory' do
    assert ::File.directory?(webserver_path)
  end

  it 'has installed nginx' do
    assert system(
      "#{webserver_path}/sbin/nginx -v"
    )
  end

  it 'has created a log directory' do
    assert ::File.directory?(webserver_log_path)
  end

  it 'has created an access log' do
    assert ::File.file?(webserver_access_log)
  end

  it 'has created an error log' do
    assert ::File.file?(webserver_error_log)
  end

  it 'has created nginx.config' do
    assert ::File.file?(webserver_config)
  end

  it 'has configured the webserver to use the access_log path' do
    assert system(
      "cat #{webserver_config} | grep 'access_log #{webserver_access_log}'"
    )
  end

  it 'has configured the webserver to use the error_log path' do
    assert system(
      "cat #{webserver_config} | grep 'error_log #{webserver_error_log}'"
    )
  end

  it 'has disabled the default site' do
    assert ::File.file?("#{webserver_path}/sites-available/default")
  end

  it 'has created a pid file directory' do
    assert ::File.directory?("#{webserver_path}/run")
  end

  it 'starts the nginx service after converge' do
    assert system(
      "service nginx status | grep -e $(cat #{webserver_path}/run/nginx.pid)"
    )
  end

  it 'notifies resources that subscribe to it' do
    assert(::File.file?('/tmp/kitchen/cache/pushit_webserver_notification_flag'),
      '/tmp/kitchen/cache/pushit_webserver_notification_flag does not exist'
    )
  end
end
