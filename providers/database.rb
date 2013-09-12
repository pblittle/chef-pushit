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

action :create do
  app_name = @current_resource.app_name
  app = Chef::Pushit.app_data_bag(app_name)

  connection_details = {
    :host => app['database']['host'],
    :port => app['database']['port'],
    :username => app['database']['root_username'],
    :password => app['database']['root_password']
  }

  mysql_database app['database']['name'] do
    connection connection_details
    action :create
  end

  new_resource.updated_by_last_action(true)
end
