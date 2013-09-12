# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::dependency' do

  it 'installs the git dependency after converge' do
    assert system('which git')
  end

  it 'installs the nodejs dependency after converge' do
    assert system('which node')
  end
end
