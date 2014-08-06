require 'spec_helper'

describe Chef::Provider::PushitWebserver do
  let(:chef_run) do
    ChefSpec::Runner.new(
      step_into: ['pushit_webserver']
    ).converge('pushit_test::webserver')
  end

  it 'creates an nginx config' do
    expect(chef_run).to create_template('nginx.conf')
  end

  it 'is subscribed to by the test' do
    expect(chef_run.file('add webserver flag')).to subscribe_to('pushit_webserver[nginx]').on(:create).delayed
  end

  let(:chef_run) do
    ChefSpec::Runner.new(
      step_into: ['pushit_webserver']
    ).converge('pushit_test::webserver_destroy')
  end

  it 'removes nginx config' do
    expect(chef_run).to delete_template('nginx.conf')
  end

  it 'is subscribed to by the test' do
    expect(chef_run.file('add webserver flag')).to subscribe_to('pushit_webserver[nginx]').on(:create).delayed
  end
end
