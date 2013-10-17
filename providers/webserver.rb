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
  true
end

def create_monit_check
  config = Chef::Resource::PushitMonit.new(
    new_resource.name,
    run_context
  )
  config.check({
    :name => new_resource.name,
    :pid_file => new_resource.pid_file,
    :start_program => "/etc/init.d/#{new_resource.name} start",
    :stop_program => "/etc/init.d/#{new_resource.name} stop",
    :uid => 'root',
    :gid => 'root'
  })
  config.run_action(:install)

  if config.updated_by_last_action?
    new_resource.updated_by_last_action(true)
  end
end

def create_webserver_config
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
end

action :create do
  create_webserver_config
  create_monit_check
end
