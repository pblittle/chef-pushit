# encoding: utf-8
#
# Cookbook Name:: pushit
# Attributes:: default
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

node.default['authorization']['sudo']['include_sudoers_d'] = true

node.default[:build_essential][:compiletime] = true

node.default[:mysql][:remove_anonymous_users] = true
node.default[:mysql][:remove_test_database] = true
node.default[:mysql][:tunable][:lower_case_table_names] = 1

node.default['nginx']['init_style'] = 'upstart'
node.default['nginx']['install_method'] = 'source'
node.default['nginx']['default_site_enabled'] = false
node.default['nginx']['dir'] = '/opt/pushit/nginx'
node.default['nginx']['log_dir'] = '/opt/pushit/nginx/log'
node.default['nginx']['binary'] = '/opt/pushit/nginx/sbin/nginx'
node.default['nginx']['source']['modules'] = [
  'nginx::http_gzip_static_module',
  'nginx::http_ssl_module',
  'nginx::http_stub_status_module'
]
node.default['nginx']['gzip_static'] = 'on'

node.default[:nodejs][:version] = '0.10.26'
node.default[:nodejs][:npm] = '1.4.7'
