require 'spec_helper'

describe Chef::Provider::PushitUser do

  let(:chef_run) do
    runner = ChefSpec::Runner.new
    runner.converge('pushit_test::user')
  end

  before do
    # load test user databag
  end

  it 'creates a deploy user' do
    expect(chef_run).to create_pushit_user('deploy')
  end
end
