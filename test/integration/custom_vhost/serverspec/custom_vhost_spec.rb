require 'spec_helper'

describe 'pushit_test::custom_vhost' do
  let(:vhost_config_path) do
    ::File.join(
      '', 'opt', 'pushit', 'nginx', 'sites-available', 'rails-example.conf'
    )
  end

  it 'config file exists' do
    expect(file(vhost_config_path)).to be_file
  end

  it 'has used our custom template' do
    expect(file(vhost_config_path).content).to contain('TEST PASSES')
    expect(file(vhost_config_path).content).to contain('test_me')
  end
end
