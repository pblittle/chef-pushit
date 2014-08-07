require 'spec_helper'

describe "#{Chef::Provider::PushitRuby}.create" do
  let(:chef_run) do
    ChefSpec::Runner.new(
      step_into: ['pushit_ruby', 'pushit_base']
    ).converge('pushit_test::ruby')
  end

  it 'installs ruby 1.9.3' do
    expect(chef_run).to install_ruby_build('1.9.3-p448')
  end

  it 'installs ruby 1.8.7' do
    expect(chef_run).to install_ruby_build('ree-1.8.7-2012.02')
  end

  it 'installs chruby' do
    pending 'not sure the best way to do this'
  end

  it 'creates chruby.sh file' do
    expect(chef_run).to create_template('/etc/profile.d/chruby.sh')
  end
end

