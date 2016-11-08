require 'spec_helper'

describe "#{Chef::Provider::PushitRuby}.create" do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(
      :step_into => %w(pushit_ruby pushit_base)
    ).converge('pushit_test::ruby')
  end

  before do
    stub_command("#{Chef::Pushit::Nodejs.node_binary} -v > /dev/null").and_return(true)
    # This stub is to protect a not_if in the ruby_build::default recipe
    stub_command('git --version >/dev/null').and_return(true)
    stub_command(/chruby --version.*/).and_return false
  end

  it 'installs ruby 1.9.3' do
    expect(chef_run).to install_ruby_build_ruby('2.3.0')
  end

  it 'installs ruby 1.8.7' do
    expect(chef_run).to install_ruby_build_ruby('ree-1.8.7-2012.02')
  end

  it 'installs chruby' do
    expect(chef_run).to run_execute('Install chruby')
  end

  it 'does not install chruby if it is already installed' do
    stub_command(/chruby --version.*/).and_return true
    expect(chef_run).to_not run_execute('Install chruby')
  end

  it 'creates chruby.sh file' do
    expect(chef_run).to create_template('/etc/profile.d/chruby.sh')
  end
end
