require 'spec_helper'

describe Chef::Provider::PushitRails do

  let(:chef_run) do
    ChefSpec::Runner.new do
      Chef::Config[:client_key] = ''
    end.converge('pushit_test::rails')
  end

  before do
    # load test app databag
  end

  it 'creates a rails app' do
    expect(chef_run).to create_pushit_rails('rails-example')
  end
end
