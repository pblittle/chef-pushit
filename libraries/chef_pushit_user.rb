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

      attr_accessor :username, :config_data

      def initialize(username = nil)
        @username = username
        @group = nil
        @home = nil
        @password = nil
        @ssh_keys = []
        @ssh_deploy_keys = []

        @config_data = config_data
      end

      def group
        Pushit.pushit_group
      end

      def home
        Pushit.pushit_path
      end

      def password
        config_data['password']
      end

      def ssh_keys
        config_data['ssh_keys'] || []
      end

      def ssh_deploy_keys
        config_data['ssh_deploy_keys'] || []
      end

      private

      def config_data
        begin
          Chef::DataBagItem.load('users', username)
        rescue Exception => ex
          raise "Unable to locate the User data bag for #{username}"
        end
      end
    end
  end
end
