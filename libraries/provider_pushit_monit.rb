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

require_relative 'provider_pushit_base'

class Chef
  class Provider
    class PushitMonit < Chef::Provider::PushitBase

      use_inline_resources if defined?(use_inline_resources)

      def action_create
        super

        recipe_eval do
          @run_context.include_recipe('monit::default')
        end

        monit_monitrc new_resource.name do
          variables(new_resource.check)
          template_source 'pushit_app.monitrc.erb'
          template_cookbook 'pushit'
        end
      end

      def action_restart
        execute "monit restart #{new_resource.name}" do
          command "monit restart #{new_resource.name}"
        end
      end
    end
  end
end
