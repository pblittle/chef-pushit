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
    # Base class for all pushit providers
    class PushitBase < Chef::Provider::LWRPBase
      include Chef::Pushit

      use_inline_resources if defined?(use_inline_resources)

      def whyrun_supported?
        false # Need to reach a point where this is true
      end

      def action_create
        pushit_user_resource.action :create
      end

      def action_delete
        log 'pushit_base does not do anything on delete' do
          level :debug
        end
      end

      private

      def user
        @user ||= Pushit::User.new
      end

      def pushit_user_resource
        r = pushit_user user.username
        r.name user.username
        r.group user.group
        r.home user.home
        r.password user.password
        r.ssh_private_key user.ssh_private_key
        r.ssh_public_key user.ssh_public_key
        r.ssh_keys user.ssh_keys
        r.ssh_deploy_keys user.ssh_deploy_keys
        r
      end
    end
  end
end
