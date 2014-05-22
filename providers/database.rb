# encoding: utf-8
#
# Cookbook Name:: pushit
# Provider:: database
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
  @current_resource = Chef::Resource::PushitDatabase.new(
    new_resource.name
  )

  run_context.include_recipe 'database::mysql'

  @current_resource
end

def whyrun_supported?
  true
end

def app
  @app ||= Pushit.app_data_bag(new_resource.name)
end

def environment
  app['environment']
end

def database
  if environment && app['database'].key?(environment)
    app['database'][environment]
  else
    app['database']
  end
end

def connection_details
  {
    :host => database['host'],
    :port => database['port'],
    :username => database['username'],
    :password => database['password']
  }
end

action :create do

  if database['host'] == 'localhost'
    run_context.node.set_unless['mysql']['server_debian_password'] =
      database['root_password']
    run_context.node.set_unless['mysql']['server_root_password'] =
      database['root_password']
    run_context.node.set_unless['mysql']['server_repl_password'] =
      database['root_password']

    run_context.include_recipe 'mysql::server'
  end

  mysql_database_user database['root_username'] do
    connection connection_details
    password database['password']
    database_name database['name']
    action :grant
    only_if do
      database['host'] == 'localhost'
    end
  end

  mysql_database database['name'] do
    connection connection_details
    action :create
  end

  new_resource.updated_by_last_action(true)
end
