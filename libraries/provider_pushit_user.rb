# encoding: utf-8
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

require 'chef/provider'

require File.expand_path('../chef_pushit', __FILE__)
# require File.expand_path('../chef_pushit_user', __FILE__)

class Chef
  class Provider
    class PushitUser < Chef::Provider

      def initialize(new_resource, run_context = nil)
        @new_resource = new_resource
        @run_context = run_context

        @group = pushit_group
        @ssh_keys = pushit_ssh_keys
        @ssh_deploy_keys = pushit_ssh_deploy_keys

        super(new_resource, run_context)
      end

      def load_current_resource; end

      def whyrun_supported?
        Pushit.whyrun_enabled?
      end

      def action_create
        create_group
        create_user
        change_home_owner
        create_ssh_keys
        create_deploy_keys
      end

      def action_create_deploy_keys
        create_deploy_keys
      end

      private

      def pushit_user
        @pushit_user ||= Pushit::User.new(new_resource.name)
      end

      def pushit_group
        @new_resource.group || pushit_user.group
      end

      def pushit_password
        pushit_user.password
      end

      def pushit_home
        @new_resource.home || pushit_user.home
      end

      def pushit_ssh_keys
        @pushit_ssh_keys || pushit_user.ssh_keys
      end

      def pushit_ssh_deploy_keys
        @pushit_ssh_deploy_keys || pushit_user.ssh_deploy_keys
      end

      def ssh_key_directory
        ::File.join(pushit_home, '.ssh')
      end

      def create_group
        group = Chef::Resource::Group.new(
          pushit_group,
          run_context
        )
        group.group_name pushit_group
        group.append true
        group.run_action(:create)

        if group.updated_by_last_action?
          new_resource.updated_by_last_action(true)
        end
      end

      def create_user
        user = Chef::Resource::User.new(
          new_resource.name,
          run_context
        )
        user.shell '/bin/bash'
        user.password pushit_password
        user.home pushit_home
        user.supports :manage_home => true
        user.system false
        user.gid Etc.getgrnam(pushit_group).gid
        user.run_action(:create)

        if user.updated_by_last_action?
          new_resource.updated_by_last_action(true)
        end
      end

      def change_home_owner
        FileUtils.chown_R(
          new_resource.username,
          pushit_group,
          pushit_home
        )
      end

      def create_ssh_key_directory
        dir = Chef::Resource::Directory.new(
          ssh_key_directory,
          run_context
        )
        dir.owner Etc.getpwnam(new_resource.name).uid
        dir.group Etc.getgrnam(pushit_group).gid
        dir.mode '0700'
        dir.recursive true
        dir.run_action(:create)

        if dir.updated_by_last_action?
          new_resource.updated_by_last_action(true)
        end
      end

      def create_ssh_keys
        create_ssh_key_directory

        pushit_ssh_keys.each do |key|
          create_deploy_key(key)
        end
      end

      def create_deploy_keys
        create_ssh_key_directory

        pushit_ssh_deploy_keys.each do |key|
          create_deploy_key(key)
          create_deploy_wrapper(key)
          create_ssh_config(key)
        end
      end

      def create_deploy_key(key)
        deploy_key = Chef::Resource::Template.new(
          ::File.join(ssh_key_directory, key['name']),
          run_context
        )
        deploy_key.source 'ssh_deploy_key.erb'
        deploy_key.cookbook 'pushit'
        deploy_key.owner new_resource.name
        deploy_key.group Etc.getgrnam(pushit_group).gid
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
          ::File.join(ssh_key_directory, "#{key['name']}_deploy_wrapper.sh"),
          run_context
        )
        wrapper.source 'ssh_wrapper.sh.erb'
        wrapper.cookbook 'pushit'
        wrapper.owner new_resource.name
        wrapper.group Etc.getgrnam(pushit_group).gid
        wrapper.mode '0755'
        wrapper.variables({
            :ssh_key_dir => ssh_key_directory,
            :ssh_key_name => key['name']
        })
        wrapper.run_action(:create)

        if wrapper.updated_by_last_action?
          new_resource.updated_by_last_action(true)
        end
      end

      def create_ssh_config(key)
        key_name = key['name']
        host_key_alias = key_name.gsub('id_rsa_', '')
        host_name = 'github.com'
        key_directory = ::File.join(pushit_home, '.ssh')
        identity_file = ::File.join(key_directory, key_name)
        config_file = ::File.join(key_directory, 'config')

        ssh_config host_key_alias do
          options 'User' => 'git',
          'HostName' => host_name,
          'IdentityFile' => identity_file
          user new_resource.name
          path config_file
        end
      end
    end
  end
end
