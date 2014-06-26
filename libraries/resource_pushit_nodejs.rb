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

require_relative 'resource_pushit_app'

class Chef
  class Resource
    class PushitNodejs < Chef::Resource::PushitApp

      SYMLINK_BEFORE_MIGRATE = {
        'env' => '.env'
      }.freeze

      def initialize(name, run_context = nil)
        super

        @resource_name = :pushit_nodejs
        @provider = Chef::Provider::PushitNodejs
        @action = :create
        @allowed_actions = [:create]

        @framework = 'nodejs'
      end

      def node_binary(arg = nil)
        set_or_return(
          :node_binary,
          arg,
          :kind_of => [String],
          :default => Pushit::Nodejs.node_binary
        )
      end

      def npm_binary(arg = nil)
        set_or_return(
          :npm_binary,
          arg,
          :kind_of => [String],
          :default => Pushit::Nodejs.npm_binary
        )
      end

      def symlink_before_migrate(arg = nil)
        set_or_return(
          :symlink_before_migrate,
          arg,
          :kind_of => [Hash],
          :default => SYMLINK_BEFORE_MIGRATE
        )
      end
    end
  end
end
