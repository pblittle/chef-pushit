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
    # Resource for installing pushit rubies
    class PushitRuby < Chef::Resource::LWRPBase
      self.resource_name = 'pushit_ruby'

      default_action :create
      actions :create

      def name(arg = nil)
        set_or_return(
          :name,
          arg,
          :kind_of => [String],
          :required => true,
          :name_attribute => true
        )
      end

      def environment(arg = nil)
        set_or_return(
          :environment,
          arg,
          :kind_of => [Hash],
          :default => {}
        )
      end

      def bundler_version(arg = nil)
        set_or_return(
          :bundler_version,
          arg,
          :kind_of => [String, Symbol]
        )
      end

      def prefix_path(arg = nil)
        set_or_return(
          :prefix_path,
          arg,
          :kind_of => [String]
        )
      end

      def bin_path(arg = nil)
        set_or_return(
          :prefix_path,
          arg,
          :kind_of => [String]
        )
      end

      def user(arg = nil)
        set_or_return(
          :user,
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
    end
  end
end
