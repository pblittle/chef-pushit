# encoding: utf-8
#
# Cookbook Name:: pushit_test
# Recipe:: webserver
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

flag_path = "#{Chef::Config[:file_cache_path]}/pushit_webserver_notification_flag"

file 'delete webserver flag' do
  path flag_path
  action :delete
end

pushit_webserver 'nginx'

file 'add webserver flag' do
  path flag_path
  action :nothing
  content 'I am here'
  # TODO: one of these two subscribes needs to work someday
  subscribes :create, 'template[/opt/pushit/nginx/nginx.conf]'
  subscribes :create, 'pushit_webserver[nginx]'
end
