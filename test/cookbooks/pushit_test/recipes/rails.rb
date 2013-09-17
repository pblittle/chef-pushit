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

pushit_user 'deploy'
pushit_webserver 'nginx'

app = 'rails-example'

pushit_ruby '1.9.3-p392'

pushit_database app

pushit_vhost app do
  config_type 'rails'
  http_port 80
  upstream_port 8080
  server_name 'localhost'
  use_ssl true
end

pushit_rails app do
  deploy_action 'deploy'
  environment 'development'
  precompile_assets true
end
