require 'spec_helper'

describe "#{Chef::Provider::PushitUser}.create" do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new
    runner.converge('pushit_test::user')
  end

  # TODO: need more tests
  before do
    # load test user databag
  end

  it 'creates a deploy user' do
    expect(chef_run).to create_pushit_user('deploy')
  end

  it 'is subscribed to by the test' do
    expect(chef_run.file('add user flag')).to subscribe_to('pushit_user[foo]').on(:create).delayed
  end
end
