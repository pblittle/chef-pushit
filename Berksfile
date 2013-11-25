site :opscode

cookbook 'monit', :github => 'phlipper/chef-monit'
cookbook 'mysql', :github => 'opscode-cookbooks/mysql'
cookbook 'newrelic', :github => 'heavywater/chef-newrelic'
cookbook 'nginx', :github => 'opscode-cookbooks/nginx'
cookbook 'runit', :github => 'opscode-cookbooks/runit'
cookbook 'ssh', :github => 'markolson/chef-ssh'

metadata

group :integration do
  cookbook 'apt'
  cookbook 'yum'
  cookbook 'mysql'
  cookbook 'pushit_test', :path => 'test/cookbooks/pushit_test'
  cookbook 'minitest-handler', :github => 'btm/minitest-handler-cookbook'
end
