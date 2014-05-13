source 'https://api.berkshelf.com'

metadata

cookbook 'campfire-deployment', :github => 'pblittle/chef-campfire-deployment', :protocol => :ssh
cookbook 'newrelic-deployment', :github => 'pblittle/chef-newrelic-deployment', :protocol => :ssh

cookbook 'certificate', :github => 'atomic-penguin/cookbook-certificate'
cookbook 'monit', :github => 'phlipper/chef-monit'
cookbook 'logrotate', :github => 'stevendanna/logrotate'
cookbook 'mysql', :github => 'opscode-cookbooks/mysql'

cookbook 'nginx', :github => 'opscode-cookbooks/nginx'
cookbook 'runit', :github => 'opscode-cookbooks/runit'
cookbook 'postgresql', :github => 'opscode-cookbooks/postgresql'
cookbook 'ruby_build', :github => 'fnichol/chef-ruby_build'
cookbook 'ssh', :github => 'markolson/chef-ssh'
cookbook 'sudo', :github => 'opscode-cookbooks/sudo'

group :integration do
  cookbook 'apt'
  cookbook 'yum'
  cookbook 'mysql'
  cookbook 'pushit_test', :path => 'test/cookbooks/pushit_test'
  cookbook 'minitest-handler', :github => 'btm/minitest-handler-cookbook'
end
