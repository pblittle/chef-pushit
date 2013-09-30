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

require File.expand_path('../provider_pushit_monit', __FILE__)

class Chef
  class Provider
    class PushitBase < Chef::Provider

      def initialize(new_resource, run_context = nil)
        initialize_filesystem
        # initialize_user

        super(new_resource, run_context)
      end

      def load_current_resource; end

      def whyrun_supported?
        Pushit.whyrun_enabled?
      end

      def action_create; end

      private

      def initialize_filesystem
        FileUtils.mkdir_p(Pushit.pushit_path, :mode => 0755)
      end

      def initialize_user
        @user = Chef::Resource::PushitUser.new(
          'deploy',
          run_context
        )
        user.run_action(:create)

        if user.updated_by_last_action?
          new_resource.updated_by_last_action(true)
        end
      end
    end
  end
end
