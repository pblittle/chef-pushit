require 'spec_helper'

describe Chef::Provider::PushitBase do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new
    runner.converge('pushit_test::base')
  end

  it 'includes the base test recipe' do
    expect(chef_run).to include_recipe('pushit_test::base')
  end

  it 'installs build-essential' do
    expect(chef_run).to install_package('build-essential')
  end

  it 'installs git' do
    expect(chef_run).to install_package('git')
  end
end
