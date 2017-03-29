# encoding: utf-8
require 'spec_helper'

context 'pushit_test::vhost' do
  let(:config_path) do
    ::File.join('', 'opt', 'pushit', 'nginx', 'sites-available')
  end

  context 'nodejs vhost' do
    let(:nodejs_config_path) do
      ::File.join(config_path, 'nodejs-example.conf')
    end

    it 'nodejs does support TLSv1' do
      expect(file(nodejs_config_path).content).to contain('TLSv1')
    end

    it 'nodejs does not support SSLv3' do
      expect(file(nodejs_config_path).content).not_to contain('SSLv3')
    end
  end

  context 'rails vhost' do
    let(:rails_config_path) do
      ::File.join(config_path, 'rails-example.conf')
    end

    it 'rails does support TLSv1' do
      expect(file(rails_config_path).content).to contain('TLSv1')
    end

    it 'rails does not support SSLv3' do
      expect(file(rails_config_path).content).not_to contain('SSLv3')
    end
  end
end
