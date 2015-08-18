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

require_relative 'chef_pushit_webserver'

class Chef
  class Resource
    # Resource for creating a webserver for your pushit apps
    class PushitWebserver < Chef::Resource::LWRPBase
      self.resource_name = 'pushit_webserver'

      default_action :create
      actions :create, :delete, :restart, :reload

      def name(arg = nil)
        set_or_return(
          :name,
          arg,
          :kind_of => [String],
          :default => 'nginx',
          :name_attribute => true
        )
      end

      def config_source(arg = nil)
        set_or_return(
          :config_source,
          arg,
          :kind_of => [String],
          :default => 'nginx.conf.erb'
        )
      end

      def config_cookbook(arg = nil)
        set_or_return(
          :config_cookbook,
          arg,
          :kind_of => [String],
          :default => 'pushit'
        )
      end

      def config_variables(arg = nil)
        set_or_return(
          :config_variables,
          arg,
          :kind_of => Hash,
          :default => {}
        )
      end
    end
  end
end
