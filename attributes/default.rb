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

default['authorization']['sudo']['include_sudoers_d'] = true

default['build-essential']['compile_time'] = true

default[:mysql][:remove_anonymous_users] = true
default[:mysql][:remove_test_database] = true
default[:mysql][:tunable][:lower_case_table_names] = 1

default[:nodejs][:install_method] = 'source'
default[:nodejs][:version] = '0.10.29'
default[:nodejs][:npm] = '1.4.21'

override['nginx']['version'] = '1.4.4'
override['nginx']['source']['version'] = '1.4.4'
override['nginx']['openssl_source']['version']  = '1.0.1j'
override['nginx']['init_style'] = 'upstart'

default['nginx']['install_method'] = 'source'
default['nginx']['default_site_enabled'] = false
default['nginx']['dir'] = '/opt/pushit/nginx'
default['nginx']['log_dir'] = '/opt/pushit/nginx/log'
default['nginx']['binary'] = '/opt/pushit/nginx/sbin/nginx'
default['nginx']['source']['modules'] = [
  'nginx::http_gzip_static_module',
  'nginx::http_ssl_module',
  'nginx::http_stub_status_module'
]
default['nginx']['gzip_static'] = 'on'

default['pushit']['chruby']['version'] = '0.3.8'

include_attribute 'nginx::source'
