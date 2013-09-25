# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::monit' do

  let(:monit_path) { ::File.join('', 'etc', 'monit') }
  let(:monit_config_path) { ::File.join(monit_path, 'conf.d') }

  it 'installs monit via application config' do
    assert system('which monit')
  end

  it 'starts the monit service after converge' do
    assert system(
      'ps -aux | grep monit'
    )
  end

  it 'creates a monitrc config file' do
    assert ::File.file?(
      ::File.join(monit_path, 'monitrc')
    )
  end

  it 'creates a nodejs-example monit config file' do
    assert ::File.file?(
      ::File.join(monit_config_path, 'nodejs-example.monitrc')
    )
  end

  it 'configures the nodejs-example config file' do
    assert ::File.read(
      ::File.join(monit_config_path, 'nodejs-example.monitrc')
    ).include?('nodejs-example')
  end
end
