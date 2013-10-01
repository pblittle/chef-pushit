site :opscode

cookbook 'monit', :github => 'phlipper/chef-monit'

metadata

group :integration do
  cookbook 'apt'
  cookbook 'yum'
  cookbook 'mysql'
  cookbook 'pushit_test', :path => 'test/cookbooks/pushit_test'
  cookbook 'minitest-handler', :github => 'btm/minitest-handler-cookbook'
end
