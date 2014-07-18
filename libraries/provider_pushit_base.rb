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
require 'chef/mixin/command'

require_relative 'chef_pushit'

class Chef
  class Provider
    class PushitBase < Chef::Provider

      include Chef::Pushit

      attr_reader :user

      def initialize(new_resource, _run_context)
        @new_resource = new_resource

        create_pushit_user
        install_gem_dependencies
      end

      def load_current_resource; end

      def whyrun_supported?
        Pushit.whyrun_supported?
      end

      def user
        @user ||= Pushit::User.new
      end

      private

      def create_pushit_user
        r = Chef::Resource::PushitUser.new(
          user.username,
          run_context
        )
        r.name user.username
        r.group user.group
        r.home user.home
        r.password user.password
        r.ssh_private_key user.ssh_private_key
        r.ssh_public_key user.ssh_public_key
        r.ssh_keys user.ssh_keys
        r.ssh_deploy_keys user.ssh_deploy_keys
        r.run_action(:create)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def install_gem_dependencies
        PUSHIT_GEM_DEPENDENCIES.each do |gem|
          r = chef_gem gem[:name] do
            version gem[:version] if gem[:version]
            action :nothing
          end
          r.run_action(:install)

          new_resource.updated_by_last_action(true) if r.updated_by_last_action?
        end
      end
    end
  end
end
