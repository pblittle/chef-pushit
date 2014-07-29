require 'spec_helper'

describe Chef::Provider::PushitVhost do
  let(:chef_run) do
    ChefSpec::Runner.new(
      step_into: ['pushit_vhost']#, 'pushit_rails', 'pushit_user', 'pushit_webserver']
    ).converge('pushit_test::vhost')
  end

  before do
    allow(Chef::DataBagItem).to(
      receive(:load).with('pushit_apps', 'rails-example').and_return(
        {'id' =>'rails-example'}
      )
    )
  end

  let(:resource_vhost) do
    chef_run.template('/etc/init/rails-example-web-1.conf')
  end

  it 'creates a vhost config' do
    expect(chef_run).to create_pushit_vhost('rails-example')
  end

  it 'notifes nginx reload if vhost config changes' do
    vhost = chef_run.pushit_vhost('rails-example')
    expect(vhost).to notify('pushit_webserver[rails-example]').to(:reload).delayed
  end
end
