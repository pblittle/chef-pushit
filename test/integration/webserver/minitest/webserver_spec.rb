# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::webserver' do

  it 'has installed nginx in /opt' do
    assert ::File.directory?('/opt/nginx')
  end

  it 'has created a log directory' do
    assert ::File.directory?('/opt/nginx/logs')
  end

  it 'has created nginx.config' do
    assert ::File.file?('/opt/nginx/nginx.conf')
  end

  it 'has created an nginx binary' do
    assert ::File.file?('/opt/nginx/sbin/nginx')
  end

  it 'has created disabled the default site' do
    refute ::File.file?('/opt/nginx/sites-enabled/default')
  end

  it 'starts the nginx service after converge' do
    assert system('service nginx status')
  end
end
