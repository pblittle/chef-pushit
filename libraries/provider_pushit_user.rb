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

require 'chef/provider/lwrp_base'

require_relative 'chef_pushit'

class Chef
  class Provider
    # Provider for creating pushit users
    class PushitUser < Chef::Provider::LWRPBase
      use_inline_resources if defined?(use_inline_resources)

      def whyrun_supported?
        true
      end

      def action_create
        resource_group.action :create
        resource_user.action :create
        resource_ssh_directory.action :create
        resource_authorized_keys.action :create
        resource_sudoers_file.action :install

        create_deploy_keys
        action_create_ssh_keys
      end

      def action_create_deploy_keys
        resource_ssh_directory.action :create

        create_deploy_keys
      end

      def action_create_ssh_keys
        return unless pushit_user.manage_ssh_keys?

        resource_ssh_private_key.action :create
        resource_ssh_public_key.action :create
      end

      private

      def pushit_user
        @pushit_user ||= Pushit::User.new(new_resource.to_hash)
      end

      def resource_group
        r = group pushit_user.group
        r.group_name pushit_user.group
        r.append true
        r
      end

      def resource_user
        r = user pushit_user.username
        r.shell '/bin/bash'
        r.home pushit_user.home
        r.gid pushit_user.group
        r.system false
        r.password pushit_user.password
        r.supports :manage_home => true
        r.manage_home true
        r
      end

      def resource_ssh_directory
        r = directory pushit_user.ssh_directory
        r.owner pushit_user.username
        r.group pushit_user.group
        r.mode '0700'
        r.recursive true
        r
      end

      def resource_ssh_private_key
        r = template pushit_user.ssh_private_key_path
        r.source 'private_key.erb'
        r.cookbook 'pushit'
        r.owner pushit_user.username
        r.group pushit_user.group
        r.mode '0600'
        r.variables(
          :private_key => pushit_user.ssh_private_key
        )
        r
      end

      def resource_ssh_public_key
        r = template pushit_user.ssh_public_key_path
        r.source 'public_key.erb'
        r.cookbook 'pushit'
        r.owner pushit_user.username
        r.group pushit_user.group
        r.mode '0600'
        r.variables(
          :public_key => pushit_user.ssh_public_key
        )
        r
      end

      def resource_authorized_keys
        r = template pushit_user.authorized_keys_path
        r.source 'authorized_keys.erb'
        r.cookbook 'pushit'
        r.owner pushit_user.username
        r.group pushit_user.group
        r.mode '0600'
        r.variables(
          :ssh_keys => pushit_user.ssh_keys
        )
        r
      end

      def resource_sudoers_file
        r = sudo pushit_user.username
        r.user "%#{pushit_user.username}"
        r.group pushit_user.group
        r.commands [
          '/usr/bin/chef-client'
        ]
        r.nopasswd true
        r
      end

      def create_deploy_keys
        pushit_user.ssh_deploy_keys.each do |key|
          resource_deploy_key(key).action :create
          resource_deploy_wrapper(key).action :create

          create_ssh_config(key)
        end
      end

      def resource_deploy_key(key)
        deploy_key = ::File.join(
          pushit_user.ssh_directory, key['name']
        )

        r = template deploy_key
        r.source 'ssh_deploy_key.erb'
        r.cookbook 'pushit'
        r.owner pushit_user.username
        r.group pushit_user.group
        r.mode '0600'
        r.variables(
          :ssh_key_data => key['data']
        )
        r.not_if { ::File.exist?(deploy_key) }
        r
      end

      def resource_deploy_wrapper(key)
        deploy_wrapper = ::File.join(
          pushit_user.ssh_directory, "#{key['name']}_deploy_wrapper.sh"
        )

        r = template deploy_wrapper
        r.source 'ssh_wrapper.sh.erb'
        r.cookbook 'pushit'
        r.owner pushit_user.username
        r.group pushit_user.group
        r.mode '0755'
        r.variables(
          :ssh_key_dir => pushit_user.ssh_directory,
          :ssh_key_name => key['name']
        )
        r.not_if { ::File.exist?(deploy_wrapper) }
        r
      end

      def create_ssh_config(key)
        key_name = key['name']
        host_key_alias = key_name.gsub('id_rsa_', '')

        identity_file = ::File.join(pushit_user.ssh_directory, key_name)
        config_file = ::File.join(pushit_user.ssh_directory, 'config')
        username = pushit_user.username

        converge_by("Create ssh config for #{username}") do
          ssh_config host_key_alias do
            options(
              'User' => 'git',
              'HostName' => 'github.com',
              'IdentityFile' => identity_file
            )
            user username
            path config_file
          end
        end
      end
    end
  end
end
