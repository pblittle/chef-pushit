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

app = 'vhost'

#pushit_webserver 'nginx'

pushit_app app do
  deploy_action 'deploy'
  environment 'development'
  revision 'master'
  vhost_config_cookbook 'pushit_test'
  vhost_config_source   'custom_vhost.conf.erb'
end
