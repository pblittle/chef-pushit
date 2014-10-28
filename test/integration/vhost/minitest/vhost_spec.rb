# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::vhost' do

  let(:config_path) do
    ::File.join('', 'opt', 'pushit', 'nginx', 'sites-available')
  end

  describe 'nodejs vhost' do

    let(:nodejs_config_path) do
      ::File.join(config_path, 'nodejs-example.conf')
    end

    it 'nodejs does support TLSv1' do
      assert File.read(nodejs_config_path).include?('TLSv1')
    end

    it 'nodejs does not support SSLv3' do
      refute File.read(nodejs_config_path).include?('SSLv3')
    end
  end

  describe 'rails vhost' do

    let(:rails_config_path) do
      ::File.join(config_path, 'rails-example.conf')
    end

    it 'rails does support TLSv1' do
      assert File.read(rails_config_path).include?('TLSv1')
    end

    it 'rails does not support SSLv3' do
      refute File.read(rails_config_path).include?('SSLv3')
    end
  end
end
