# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::rails' do

  let(:pushit_path) { ::File.join('', 'opt', 'pushit') }

  let(:pushit_app_path) { ::File.join(pushit_path, 'apps', 'rails-example') }

  let(:pushit_pid_path) do
    ::File.join(pushit_app_path, 'current', 'tmp', 'pids', 'upstart.pid')
  end

  it 'has created the base pushit directory' do
    assert File.directory?(pushit_path)
  end

  it 'has created a rails app in pushit base' do
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

  it 'has symlinked the current release' do
    assert File.symlink?(
      ::File.join(pushit_app_path, 'current')
    )
  end

  it 'has created database.yml' do
    assert File.file?(
      ::File.join(pushit_app_path, 'shared', 'config', 'database.yml')
    )
  end

  it 'has symlinked database.yml to current' do
    assert File.symlink?(
      ::File.join(pushit_app_path, 'current', 'config', 'database.yml')
    )
  end

  it 'has created a service config' do
    assert File.file?(
      ::File.join('', 'etc', 'init', 'rails-example.conf')
    )
  end

  # This only works if Unicorn is in the app Gemfile
  #
  # it 'starts the rails-example service after converge' do
  #   assert system(
  #     "service rails-example status | grep -e $(cat #{pushit_pid_path})"
  #   )
  # end
end
