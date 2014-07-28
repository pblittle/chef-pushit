# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::custom-vhost' do

  let(:vhost_config_path) do
    ::File.join(
      '', 'opt', 'pushit', 'nginx', 'sites-available', 'rails-example.conf'
    )
  end

  it 'config file exists' do
    assert ::File.exist?(vhost_config_path)
  end

  it 'has used our custom template' do
    assert ::File.readlines(vhost_config_path).grep(/TEST PASSES/).length > 0
  end
end
