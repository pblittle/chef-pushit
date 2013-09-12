# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::nodejs' do

  let(:pushit_path) { ::File.join('', 'opt', 'pushit', 'apps') }
  let(:pushit_app_path) { ::File.join(pushit_path, 'nodejs-example') }
  let(:pushit_pid_path) do
    ::File.join(pushit_app_path, 'current', 'pids', 'upstart.pid')
  end

  it 'has created the base pushit directory' do
    assert File.directory?(pushit_path)
  end

  it 'has created a nodejs app in pushit base' do
    assert File.directory?(pushit_app_path)
  end

  it 'has created a log directory' do
    assert File.directory?(
      ::File.join(pushit_app_path, 'shared', 'log')
    )
  end

  it 'has created a pids directory' do
    assert File.directory?(
      ::File.join(pushit_app_path, 'shared', 'pids')
    )
  end

  it 'has symlinked the current directory' do
    assert File.symlink?(
      ::File.join(pushit_app_path, 'current')
    )
  end

  it 'has created a service config' do
    assert File.file?(
      ::File.join('', 'etc', 'init', 'nodejs-example.conf')
    )
  end

  it 'starts the nodejs-example service after converge' do
    assert system(
      "service nodejs-example status | grep -e $(cat #{pushit_pid_path})"
    )
  end
end
