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

require_relative 'chef_pushit'
require_relative 'chef_pushit_user'

class Chef
  class Provider
    class PushitUser < Chef::Provider

      def initialize(new_resource, run_context = nil)
        @new_resource = new_resource
        @run_context = run_context

        super(new_resource, run_context)
      end

      def load_current_resource; end

      def whyrun_supported?
        Pushit.whyrun_enabled?
      end

      def action_create
        create_group
        create_user
        create_ssh_directory
        create_ssh_keys
        create_deploy_keys
        create_authorized_keys
        create_sudoers_file
      end

      def action_create_deploy_keys
        create_ssh_directory
        create_deploy_keys
      end

      private

      def pushit_user
        @pushit_user ||= Pushit::User.new(new_resource.to_hash)
      end

      def create_user
        r = Chef::Resource::User.new(
          pushit_user.username,
          run_context
        )
        r.shell '/bin/bash'
        r.password pushit_user.password
        r.home pushit_user.home
        r.manage_home true
        r.supports :manage_home => true
        r.system false
        r.gid Etc.getgrnam(pushit_user.group).gid
        r.run_action(:create)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_group
        r = Chef::Resource::Group.new(
          pushit_user.group,
          run_context
        )
        r.group_name pushit_user.group
        r.append true
        r.run_action(:create)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_ssh_directory
        r = Chef::Resource::Directory.new(
          pushit_user.ssh_directory,
          run_context
        )
        r.owner Etc.getpwnam(pushit_user.username).uid
        r.group Etc.getgrnam(pushit_user.group).gid
        r.mode '0700'
        r.recursive true
        r.run_action(:create)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_ssh_keys
        return unless pushit_user.manage_ssh_keys?

        create_ssh_private_key
        create_ssh_public_key
      end

      def create_ssh_private_key
        r = Chef::Resource::Template.new(
          pushit_user.ssh_private_key_path,
          run_context
        )
        r.source 'private_key.erb'
        r.cookbook 'pushit'
        r.owner Etc.getpwnam(pushit_user.username).uid
        r.group Etc.getgrnam(pushit_user.group).gid
        r.mode '0600'
        r.variables(
          :private_key => pushit_user.ssh_private_key
        )
        r.run_action(:create)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_ssh_public_key
        r = Chef::Resource::Template.new(
          pushit_user.ssh_public_key_path,
          run_context
        )
        r.source 'public_key.erb'
        r.cookbook 'pushit'
        r.owner Etc.getpwnam(pushit_user.username).uid
        r.group Etc.getgrnam(pushit_user.group).gid
        r.mode '0600'
        r.variables(
          :public_key => pushit_user.ssh_public_key
        )
        r.run_action(:create)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_authorized_keys
        r = Chef::Resource::Template.new(
          pushit_user.authorized_keys_path,
          run_context
        )
        r.source 'authorized_keys.erb'
        r.cookbook 'pushit'
        r.owner Etc.getpwnam(pushit_user.username).uid
        r.group Etc.getgrnam(pushit_user.group).gid
        r.mode '0600'
        r.variables(
          :ssh_keys => pushit_user.ssh_keys
        )
        r.run_action(:create)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_sudoers_file
        r = Chef::Resource::Sudo.new(
          pushit_user.username,
          run_context
        )
        r.user "%#{pushit_user.username}"
        r.group pushit_user.group
        r.commands [
          '/usr/bin/chef-client'
        ]
        r.nopasswd true
        r.run_action(:install)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_deploy_keys
        pushit_user.ssh_deploy_keys.each do |key|
          create_deploy_key(key)
          create_deploy_wrapper(key)
          create_ssh_config(key)
        end
      end

      def create_deploy_key(key)
        deploy_key = ::File.join(
          pushit_user.ssh_directory, key['name']
        )

        r = Chef::Resource::Template.new(
          deploy_key,
          run_context
        )
        r.source 'ssh_deploy_key.erb'
        r.cookbook 'pushit'
        r.owner pushit_user.username
        r.group Etc.getgrnam(pushit_user.group).gid
        r.mode '0600'
        r.variables(
          :ssh_key_data => key['data']
        )
        r.run_action(:create)
        r.not_if { ::File.exist?(deploy_key) }

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_deploy_wrapper(key)
        deploy_wrapper = ::File.join(
          pushit_user.ssh_directory, "#{key['name']}_deploy_wrapper.sh"
        )

        r = Chef::Resource::Template.new(
          deploy_wrapper,
          run_context
        )
        r.source 'ssh_wrapper.sh.erb'
        r.cookbook 'pushit'
        r.owner pushit_user.username
        r.group Etc.getgrnam(pushit_user.group).gid
        r.mode '0755'
        r.variables(
          :ssh_key_dir => pushit_user.ssh_directory,
          :ssh_key_name => key['name']
        )
        r.run_action(:create)
        r.not_if { ::File.exist?(deploy_wrapper) }

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_ssh_config(key)
        key_name = key['name']
        host_key_alias = key_name.gsub('id_rsa_', '')
        host_name = 'github.com'
        identity_file = ::File.join(pushit_user.ssh_directory, key_name)
        config_file = ::File.join(pushit_user.ssh_directory, 'config')
        username = pushit_user.username

        ssh_config host_key_alias do
          options(
            'User' => 'git',
            'HostName' => host_name,
            'IdentityFile' => identity_file
          )
          user username
          path config_file
          not_if { `grep #{identity_file} #{config_file}` }
        end
      end
    end
  end
end
