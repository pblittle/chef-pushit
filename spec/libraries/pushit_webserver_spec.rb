require 'spec_helper'

describe "#{Chef::Provider::PushitWebserver}.create" do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(
      :step_into => %w(pushit_webserver pushit_base)
    ).converge('pushit_test::webserver')
  end

  it 'is subscribed to by the test' do
    expect(chef_run.file('add webserver flag')).to subscribe_to('pushit_webserver[nginx]').on(:create).delayed
  end

  it 'used upstart to run nginx' do
    expect(chef_run.node.override['nginx']['init_style']).to eq('upstart')
    expect(chef_run).to start_service('nginx').with(:provider => Chef::Provider::Service::Upstart)
  end
end

describe "#{Chef::Provider::PushitWebserver}.delete" do
  let(:chef_run) do
    ChefSpec::Runner.new(
      :step_into => %w(pushit_webserver)
    ).converge('pushit_test::webserver_delete')
  end

  it 'does not create the nginx config' do
    expect(chef_run).to_not create_template('nginx.conf')
  end

  it 'is subscribed to by the test' do
    expect(chef_run.file('add webserver flag')).to subscribe_to('pushit_webserver[nginx]').on(:create).delayed
  end
end

describe "#{Chef::Provider::PushitWebserver}.restart" do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(
      :step_into => %w(pushit_webserver)
    ).converge('pushit_test::webserver_restart')
  end

  it 'restarts nginx' do
    pending
    expect(chef_run).to restart_service('nginx')
  end
end

describe "#{Chef::Provider::PushitWebserver}.reload" do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(
      :step_into => %w(pushit_webserver)
    ).converge('pushit_test::webserver_reload')
  end

  it 'reloads nginx' do
    pending
    expect(chef_run).to reload_service('nginx')
  end
end
