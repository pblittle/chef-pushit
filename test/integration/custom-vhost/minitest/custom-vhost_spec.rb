# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::custom-vhost' do

  let(:vhost_config_path) { ::File.join('', 'opt', 'pushit', 'nginx', 'sites-available', 'vhost.conf') }

  it 'config file exists' do
    assert ::File.exists?(vhost_config_path)
  end

  it 'has used our custom template' do
    assert ::File.readlines(vhost_config_path).grep(/TEST PASSES/).length > 0
  end
#
#   it 'shouldnt pass this' do
#     file('/opt/pushit/nginx/sites-available/vhost.conf').must_include 'TEST NO PASS'
#   end
end
