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

require 'chef/resource'

class Chef
  class Resource
    class PushitUser < Chef::Resource

      def initialize(name, run_context = nil)
        super

        @resource_name = :pushit_user
        @provider = Chef::Provider::PushitUser
        @action = :create
        @allowed_actions.push :create, :create_deploy_keys

        @username = name
        @group = nil
        @home = nil
        @ssh_keys = []
        @ssh_deploy_keys = []
      end

      def username(arg = nil)
        set_or_return(
          :username,
          arg,
          :kind_of => [String]
        )
      end

      def group(arg = nil)
        set_or_return(
          :group,
          arg,
          :kind_of => [String]
        )
      end

      def home(arg = nil)
        set_or_return(
          :home,
          arg,
          :kind_of => [String]
        )
      end

      def ssh_keys(arg = nil)
        set_or_return(
          :ssh_keys,
          arg,
          :kind_of => [Array]
        )
      end

      def ssh_deploy_keys(arg = nil)
        set_or_return(
          :ssh_deploy_keys,
          arg,
          :kind_of => [Array]
        )
      end
    end
  end
end
