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

require 'chef/resource/lwrp_base'

class Chef
  class Resource
    # resource for creating users for pushit library
    class PushitUser < Chef::Resource::LWRPBase
      self.resource_name = 'pushit_user'

      default_action :create
      actions :create, :create_deploy_keys, :create_ssh_keys

      def username(arg = nil)
        set_or_return(
          :username,
          arg,
          :kind_of => [String],
          :regex => /^[a-z0-9\-_]+$/,
          :name_attribute => true
        )
      end

      def group(arg = nil)
        set_or_return(
          :group,
          arg,
          :kind_of => [String],
          :regex => /^[a-z0-9\-_]+$/
        )
      end

      def home(arg = nil)
        set_or_return(
          :home,
          arg,
          :kind_of => [String]
        )
      end

      def password(arg = nil)
        set_or_return(
          :password,
          arg,
          :kind_of => [String]
        )
      end

      def ssh_private_key(arg = nil)
        set_or_return(
          :ssh_private_key,
          arg,
          :kind_of => [String]
        )
      end

      def ssh_public_key(arg = nil)
        set_or_return(
          :ssh_public_key,
          arg,
          :kind_of => [String]
        )
      end

      def ssh_keys(arg = nil)
        set_or_return(
          :ssh_keys,
          arg,
          :kind_of => [Array],
          :default => []
        )
      end

      def ssh_deploy_keys(arg = nil)
        set_or_return(
          :ssh_deploy_keys,
          arg,
          :kind_of => [Array]
        )
      end

      def sudo_commands(arg = nil)
        set_or_return(
          :sudo_commands,
          arg,
          :kind_of => [Array]
        )
      end

      def to_hash
        {
          :username => username,
          :group => group,
          :home => home,
          :password => password,
          :ssh_private_key => ssh_private_key,
          :ssh_public_key => ssh_public_key,
          :ssh_keys => ssh_keys,
          :ssh_deploy_keys => ssh_deploy_keys
        }
      end
    end
  end
end
