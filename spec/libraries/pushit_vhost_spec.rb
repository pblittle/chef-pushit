require 'spec_helper'

describe Chef::Provider::PushitVhost do

  let(:chef_run) do
    runner = ChefSpec::Runner.new
    runner.converge('pushit_test::vhost')
  end

  let(:resource_vhost) do
    chef_run.template('/etc/init/rails-example-web-1.conf')
  end

  it 'creates a vhost config' do
    expect(chef_run).to create_pushit_vhost('rails-example')
  end

  it 'notifes nginx reload if vhost config changes' do
    pending

    expect(resource_vhost).to notify('...').immediately
  end
end
