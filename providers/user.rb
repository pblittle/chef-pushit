# encoding: utf-8
#
# Cookbook Name:: pushit
# Provider:: user
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
  @current_resource = Chef::Resource::PushitUser.new(
    new_resource.name
  )

  @current_resource
end

def whyrun_supported?
  true
end

action :create do

  create_group
  create_user
  change_home_owner

  setup_deploy_keys

  new_resource.updated_by_last_action(true)
end

private

def create_group
  group = Chef::Resource::Group.new(
    @new_resource.group,
    @run_context
  )
  group.append true
  group.run_action(:create)

  new_resource.updated_by_last_action(true) if group.updated_by_last_action?
end

def create_user
  user = Chef::Resource::User.new(
    new_resource.username,
    @run_context
  )
  user.shell '/bin/bash'
  user.home new_resource.home
  user.supports :manage_home => true
  user.system false
  user.uid Etc.getgrnam(new_resource.username).gid
  user.gid Etc.getgrnam(new_resource.group).gid
  user.run_action(:create)

  if user.updated_by_last_action?
    new_resource.updated_by_last_action(true)
  end
end

def create_deploy_key_directory
  dir = Chef::Resource::Directory.new(
    deploy_key_directory,
    @run_context
  )
  dir.owner @new_resource.username
  dir.group Etc.getpwnam(@new_resource.username).gid
  dir.mode '0700'
  dir.recursive true
  dir.run_action(:create)

  if dir.updated_by_last_action?
    new_resource.updated_by_last_action(true)
  end
end

def change_home_owner
  FileUtils.chown_R(
    @new_resource.username,
    @new_resource.group,
    Pushit.pushit_path
  )
end

def setup_deploy_keys
  create_deploy_key_directory
  deploy_keys.each do |key|
    create_deploy_key(key)
    create_deploy_wrapper(key)
  end
end

def create_deploy_key(key)
  deploy_key = Chef::Resource::Template.new(
    ::File.join(deploy_key_directory, key['name']),
    @run_context
  )
  deploy_key.source 'ssh_deploy_key.erb'
  deploy_key.cookbook 'pushit'
  deploy_key.owner @new_resource.username
  deploy_key.group Etc.getpwnam(@new_resource.username).gid
  deploy_key.mode '0600'
  deploy_key.variables({
    :ssh_key_data => key['data']
  })
  deploy_key.run_action(:create)

  if deploy_key.updated_by_last_action?
    new_resource.updated_by_last_action(true)
  end
end

def create_deploy_wrapper(key)
  wrapper = Chef::Resource::Template.new(
    ::File.join(deploy_key_directory, "#{key['name']}_deploy_wrapper.sh"),
    @run_context
  )
  wrapper.source 'ssh_wrapper.sh.erb'
  wrapper.cookbook 'pushit'
  wrapper.owner @new_resource.username
  wrapper.group Etc.getpwnam(@new_resource.username).gid
  wrapper.mode '0755'
  wrapper.variables({
    :ssh_key_dir => deploy_key_directory,
    :ssh_key_name => key['name']
  })
  wrapper.run_action(:create)

  if wrapper.updated_by_last_action?
    new_resource.updated_by_last_action(true)
  end
end

def deploy_key_directory
  ::File.join(@new_resource.home, '.ssh')
end

def deploy_keys
  user = data_bag_item('users', @new_resource.username)
  user['ssh_deploy_keys'] || []
end
