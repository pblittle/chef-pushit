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

class Chef
  class Provider
    class PushitBase < Chef::Provider

      attr_accessor :pushit_user

      def initialize(new_resource, run_context = nil)
        create_filesystem
        create_user
      end

      def whyrun_supported?
        Pushit.whyrun_enabled?
      end

      def pushit_user
        @pushit_user ||= Pushit::User.new
      end

      private

      def create_filesystem
        return if Dir.exist?(pushit_user.home)

        FileUtils.mkdir_p(
          pushit_user.home, :mode => 0755
        )
      end

      def create_user
        r = Chef::Resource::PushitUser.new(
          pushit_user.username,
          run_context
        )
        r.name pushit_user.username
        r.group pushit_user.group
        r.home pushit_user.home
        r.password pushit_user.password
        r.ssh_deploy_keys pushit_user.ssh_deploy_keys
        r.generate_ssh_keys true
        r.run_action(:create)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end
    end
  end
end
