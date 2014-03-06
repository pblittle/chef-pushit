# encoding: utf-8
#
# Cookbook Name:: pushit
# Library:: user
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

require ::File.expand_path('../chef_pushit', __FILE__)

class Chef
  module Pushit
    class User

      attr_accessor :ssh_private_key, :ssh_public_key
      attr_accessor :ssh_deploy_keys

      def initialize(args = {})
        args = { username: args } if args.is_a?(String)
        @args = args

        @ssh_private_key = ssh_private_key
        @ssh_public_key = ssh_public_key
        @ssh_deploy_keys = ssh_deploy_keys

        @config_data = config_data
      end

      def username
        @args[:username] || Pushit.pushit_user
      end

      def group
        @args[:group] || Pushit.pushit_group
      end

      def home
        @args[:home] || Pushit.pushit_path
      end

      def password
        config_data['password']
      end

      def manage_ssh_keys?
        (ssh_private_key && !ssh_private_key.empty?) &&
          (ssh_public_key && !ssh_public_key.empty?)
      end

      def ssh_directory
        File.join(home, '.ssh')
      end

      def ssh_key_type
        ssh_private_key.include?('BEGIN RSA PRIVATE KEY') ? 'rsa' : 'dsa'
      end

      def ssh_private_key
        config_data['ssh_private_key'] || @args[:ssh_private_key]
      end

      def ssh_public_key
        config_data['ssh_public_key'] || @args[:ssh_public_key]
      end

      def ssh_keys
        config_data['ssh_keys'] || []
      end

      def ssh_deploy_keys
        config_data['ssh_deploy_keys'] || []
      end

      def ssh_private_key_path
        ::File.join(ssh_directory, "id_#{ssh_key_type}")
      end

      def ssh_public_key_path
        "#{ssh_private_key_path}.pub"
      end

      def authorized_keys_path
        ::File.join(ssh_directory, 'authorized_keys')
      end

      def runit_service_dir
        File.join(home, 'service')
      end

      def runit_sv_dir
        File.join(home, 'sv')
      end

      private

      def config_data
        Chef::DataBagItem.load('users', username)
      rescue
        {}
      end
    end
  end
end
