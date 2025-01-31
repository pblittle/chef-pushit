# encoding: utf-8
#
# Cookbook Name:: pushit_test
# Recipe:: rails
#
# Author:: P. Barrett Little (<barrett@barrettlittle.com>)
#
# Copyright 2013, P. Barrett Little
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'pushit_test::base'

app = 'rails-example'

pushit_database app do
  config node[:pushit_test][app][:config][:database]
end

pushit_webserver 'nginx'

node.run_state[:test_config_values] = { :env => { :test_val_2 => 'true', :test_val_1 => 'true' } }

pushit_rails app do
  deploy_action 'deploy'
  environment 'test'
  precompile_assets true
  migrate true
  unicorn_worker_processes 1
  revision 'b41e9a3676edb38a28463c23112a25a23d850cf1'
  config_files ['test_file.txt']
  config [node[:pushit_test][app][:config], node.run_state[:test_config_values]]
end

pushit_rails(app + '2') do
  name app
  deploy_action 'deploy'
  environment 'test'
  precompile_assets true
  migrate true
  unicorn_worker_processes 1
  config [node[:pushit_test][app][:config], node.run_state[:test_config_values]]
  revision 'ca0ad715cb68e58e9b28c442f2e17189dc9c29ad'
end
