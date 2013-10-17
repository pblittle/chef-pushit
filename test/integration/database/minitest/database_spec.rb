# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::database' do
  it 'installs a mysql server' do
    assert system('which mysql')
  end
end
