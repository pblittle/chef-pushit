require 'spec_helper'

describe Chef::Provider::PushitVhost do
  let(:chef_run) do
    ChefSpec::Runner.new(
      step_into => %w(pushit_vhost)
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
    chef_run.template('/opt/pushit/nginx/sites-available/rails-example.conf')
  end

  it 'creates a vhost config' do
    expect(chef_run).to create_pushit_vhost('rails-example')
  end

  it 'adds a nginx site' do
    pending 'need to figure out the matchers for this'
    expect(chef_run).to enable_nginx_site('/opt/pushit/nginx/sites-available/rails-example.conf')
  end

  it 'notifes nginx reload if vhost config changes' do
    pending 'the internals of vhost need to do this, not vhost itself'
    vhost = chef_run.pushit_vhost('rails-example')
    expect(vhost).to notify('pushit_webserver[rails-example]').to(:reload).delayed
  end
end
