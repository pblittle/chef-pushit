require 'spec_helper'

describe Chef::Provider::PushitVhost do
  let(:chef_run) do
    ChefSpec::Runner.new(
      :step_into => %w(pushit_vhost)
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
    pending 'need to figure out the matchers for this because it is a definition rather than a resource'
    expect(chef_run).to enable_nginx_site('/opt/pushit/nginx/sites-available/rails-example.conf')
  end

  it 'notifes nginx reload if vhost config changes' do
    vhost_config = chef_run.template('/opt/pushit/nginx/sites-available/rails-example.conf')
    expect(vhost_config).to notify('pushit_webserver[nginx]').to(:reload).delayed
  end
end
