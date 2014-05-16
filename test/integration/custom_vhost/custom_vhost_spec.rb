# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::custom_vhost' do

  it 'has used our custom template' do
    assert system(
      "grep -e \"TEST PASSES\" /opt/pushit/nginx/sites-enabled/rails-example.conf"
    )
  end
end
