site :opscode

cookbook 'campfire-deployment', :path => '../chef-campfire-deployment'
cookbook 'certificate', :github => 'atomic-penguin/cookbook-certificate'
cookbook 'monit', :github => 'phlipper/chef-monit'
cookbook 'logrotate', :github => 'stevendanna/logrotate'
cookbook 'mysql', :github => 'opscode-cookbooks/mysql'
cookbook 'newrelic', :github => 'heavywater/chef-newrelic'
cookbook 'newrelic-deployment', :path => '../chef-newrelic-deployment'
cookbook 'nginx', :github => 'opscode-cookbooks/nginx'
cookbook 'runit', :github => 'opscode-cookbooks/runit'
cookbook 'ssh', :github => 'markolson/chef-ssh'
cookbook 'sudo', :github => 'opscode-cookbooks/sudo'
cookbook 'ruby_build', :github => 'fnichol/chef-ruby_build'

metadata

group :integration do
  cookbook 'apt'
  cookbook 'yum'
  cookbook 'mysql'
  cookbook 'pushit_test', :path => 'test/cookbooks/pushit_test'
  cookbook 'minitest-handler', :github => 'btm/minitest-handler-cookbook'
end
