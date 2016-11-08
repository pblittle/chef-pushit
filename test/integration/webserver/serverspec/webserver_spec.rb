require 'spec_helper'

context 'webserver tests' do
  let(:pushit_path) { ::File.join('', 'opt', 'pushit') }

  let(:nginx_install_path) { ::File.join('', 'opt', 'nginx-1.4.4') }

  let(:webserver_path) { ::File.join(pushit_path, 'nginx') }

  let(:webserver_config) { ::File.join(webserver_path, 'nginx.conf') }

  let(:webserver_log_path) { ::File.join(webserver_path, 'log') }

  let(:webserver_access_log) { ::File.join(webserver_log_path, 'access.log') }

  let(:webserver_error_log) { ::File.join(webserver_log_path, 'error.log') }

  it 'has created the base pushit directory' do
    expect(file(pushit_path)).to be_directory
  end

  it 'has created the nginx install directory' do
    expect(file(webserver_path)).to be_directory
  end

  it 'has installed nginx' do
    expect(command("#{nginx_install_path}/sbin/nginx -v").exit_status).to eq(0)
  end

  it 'has created a log directory' do
    expect(file(webserver_log_path)).to be_directory
  end

  it 'has created an access log' do
    expect(file(webserver_access_log)).to be_file
  end

  it 'has created an error log' do
    expect(file(webserver_error_log)).to be_file
  end

  it 'has created nginx.config' do
    expect(file(webserver_config)).to be_file
  end

  it 'has configured the webserver to use the access_log path' do
    expect(file(webserver_config).content).to contain "access_log #{webserver_access_log}"
  end

  it 'has configured the webserver to use the error_log path' do
    expect(file(webserver_config).content).to contain "error_log #{webserver_error_log}"
  end

  it 'has disabled the default site' do
    expect(file(::File.file?("#{webserver_path}/sites-available/default"))).not_to exist
  end

  it 'has created a pid file directory' do
    expect(file("#{webserver_path}/run")).to be_directory
  end

  it 'starts the nginx service after converge' do
    expect(service('nginx')).to be_running
  end

  it 'exposes nginx resources for notifications' do
    skip 'I need to figure something out here'
    expect(file(::File.file?('/tmp/kitchen/cache/pushit_webserver_notification_flag'))).to be_file
  end

  it 'runs nginx under upstart' do
    expect(service('nginx')).to be_running.under('upstart')
  end
end
