# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::webserver' do

  let(:pushit_path) { ::File.join('', 'opt', 'pushit') }

  let(:webserver_path) { ::File.join(pushit_path, 'nginx') }

  it 'has created the base pushit directory' do
    assert ::File.directory?(pushit_path)
  end

  it 'has installed nginx' do
    assert ::File.directory?(webserver_path)
  end

  it 'has created a log directory' do
    assert ::File.directory?("#{webserver_path}/log")
  end

  it 'has created a pid file directory' do
    assert ::File.directory?("#{webserver_path}/run")
  end

  it 'has created nginx.config' do
    assert ::File.file?("#{webserver_path}/nginx.conf")
  end

  it 'has disabled the default site' do
    assert ::File.file?("#{webserver_path}/sites-available/default")
  end

  it 'starts the nginx service after converge' do
    assert system(
      "service nginx status | grep -e $(cat #{webserver_path}/run/nginx.pid)"
    )
  end
end
