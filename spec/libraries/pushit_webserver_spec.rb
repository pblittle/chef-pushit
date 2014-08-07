require 'spec_helper'

describe "#{Chef::Provider::PushitWebserver}.create" do
  let(:chef_run) do
    ChefSpec::Runner.new(
      step_into: ['pushit_webserver', 'pushit_base']
    ).converge('pushit_test::webserver')
  end

  it 'creates the deploy user' do
    expect(chef_run).to create_pushit_user('deploy')
  end

  it 'creates an nginx config' do
    expect(chef_run).to create_template('nginx.conf')
  end

  it 'is subscribed to by the test' do
    expect(chef_run.file('add webserver flag')).to subscribe_to('pushit_webserver[nginx]').on(:create).delayed
  end
end

describe "#{Chef::Provider::PushitWebserver}.delete" do
  let(:chef_run) do
    ChefSpec::Runner.new(
      step_into: ['pushit_webserver']
    ).converge('pushit_test::webserver_delete')
  end

  it 'removes nginx config' do
    expect(chef_run).to delete_template('nginx.conf')
  end

  it 'does not create the nginx config' do
    expect(chef_run).to_not create_template('nginx.conf')
  end

# I don't think we should delete the user just because the webserver is deleted.
  it 'removes the user' do
    pending 'not implemented until we have the Pushit_Base.action_delete method ready'
    expect(chef_run).to delete_pushit_user('deploy')
  end

  it 'is subscribed to by the test' do
    expect(chef_run.file('add webserver flag')).to subscribe_to('pushit_webserver[nginx]').on(:create).delayed
  end
end
