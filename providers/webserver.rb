# encoding: utf-8
#
# Cookbook Name:: pushit
# Provider:: webserver
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

def load_current_resource
  @current_resource = Chef::Resource::PushitWebserver.new(
    new_resource.type
  )

  run_context.include_recipe 'nginx::default'

  @current_resource
end

def whyrun_supported?
  false
end

action :create do
  template 'nginx.conf' do
    path "#{new_resource.config_path}/nginx.conf"
    cookbook new_resource.config_cookbook
    source new_resource.config_source
    owner 'root'
    group 'root'
    mode '0644'
    variables({
      :log_path => new_resource.log_path,
      :pid_file => new_resource.pid_file
    })
  end

  pushit_monit 'nginx' do
    check({
      :name => 'nginx',
      :pid_file => new_resource.pid_file,
      :start_program => '/etc/init.d/nginx start',
      :stop_program => '/etc/init.d/nginx stop',
      :uid => 'root',
      :gid => 'root'
    })
  end

  new_resource.updated_by_last_action(true)
end
