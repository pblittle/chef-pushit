# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::custom_vhost' do

  it 'has used our custom template' do
    file('/opt/pushit/nginx/sites-enabled/rails-example.conf').must_include 'TEST PASSES'
  end

  it 'shouldnt pass this' do
    file('/opt/pushit/nginx/sites-enabled/rails-example.conf').must_include 'TEST NO PASS'
  end
end
