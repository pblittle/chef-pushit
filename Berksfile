source 'https://api.berkshelf.com'

metadata

cookbook 'build-essential', :github => 'opscode-cookbooks/build-essential'

cookbook 'campfire-deployment', :git => 'git@github.com:pblittle/chef-campfire-deployment.git'
cookbook 'newrelic-deployment', :git => 'git@github.com:pblittle/chef-newrelic-deployment.git'

cookbook 'certificate', :github => 'atomic-penguin/cookbook-certificate'
cookbook 'monit', :git => 'git@github.com:phlipper/chef-monit.git'
cookbook 'logrotate', :git => 'git@github.com:stevendanna/logrotate.git'
cookbook 'mysql', :github => 'opscode-cookbooks/mysql'

cookbook 'nodejs', :git => 'git@github.com:mdxp/nodejs-cookbook.git'
cookbook 'nginx', :git => 'git@github.com:opscode-cookbooks/nginx.git', :tag => 'v2.6.2'
cookbook 'runit', :github => 'opscode-cookbooks/runit'
cookbook 'postgresql', :github => 'opscode-cookbooks/postgresql'
cookbook 'ruby_build', :github => 'fnichol/chef-ruby_build'
cookbook 'ssh', :github => 'markolson/chef-ssh'
cookbook 'sudo', :github => 'opscode-cookbooks/sudo'

group :integration do
  cookbook 'apt', :github => 'opscode-cookbooks/apt'
  cookbook 'yum', :github => 'opscode-cookbooks/yum'
  cookbook 'mysql', :github => 'opscode-cookbooks/mysql'
  cookbook 'pushit_test', :path => 'test/cookbooks/pushit_test'
  cookbook 'minitest-handler', :github => 'btm/minitest-handler-cookbook'
end
