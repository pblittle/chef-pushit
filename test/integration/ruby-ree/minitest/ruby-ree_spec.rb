# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::ruby-ree' do

  it 'has successfully installed ruby_build' do
    assert system(
      'su - deploy -c "which ruby-build"'
    )
  end

  it 'has successfully installed chruby' do
    assert system(
      'su - deploy -c "which chruby-exec"'
    )
  end

  it 'has created chruby.sh' do
    assert ::File.read(
      '/etc/profile.d/chruby.sh'
    ).include?('ree-1.8.7-2012.02')
  end

  it 'chruby.sh sources auto.sh' do
    assert ::File.read(
      '/etc/profile.d/chruby.sh'
    ).include?('auto.sh')
  end
end
