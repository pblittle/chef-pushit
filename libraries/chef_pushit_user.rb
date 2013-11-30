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

      attr_accessor :username, :group, :home, :password
      attr_accessor :ssh_deploy_keys, :ssh_directory

      def initialize(args = {})

        args = { username: args } if args.is_a?(String)

        @username = args[:username] || default_username
        @group = args[:group] || username
        @home = args[:home] || default_home

        @ssh_directory = nil

        @password = password

        @ssh_public_key = args[:ssh_public_key] || ssh_public_key
        @ssh_private_key = args[:ssh_private_key] || ssh_private_key
        @ssh_deploy_keys = ssh_deploy_keys

        @config_data = config_data
      end

      def default_username
        Pushit.pushit_user
      end

      def default_home
        Pushit.pushit_path
      end

      def password
        config_data['password'] || nil
      end

      def ssh_directory
        File.join(home, '.ssh')
      end

      def create_ssh_keys
        # ssh_directory_exists?

        unless ::File.exists?(ssh_public_key) &&
            ::File.exists?(ssh_private_key)
          `ssh-keygen -b 2048 -t rsa -f #{ssh_private_key} -P ''`
        end
      end

      def ssh_directory_exists?
        unless File.directory?(ssh_directory)
          FileUtils.mkdir_p(
            ssh_directory, :mode => 0700
          )
        end
      end

      def ssh_private_key
        ::File.join(ssh_directory, 'id_rsa')
      end

      def ssh_public_key
        "#{ssh_private_key}.pub"
      end

      def ssh_deploy_keys
        config_data['ssh_deploy_keys'] || []
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
