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

require File.expand_path('../resource_pushit_app', __FILE__)

class Chef
  class Resource
    class PushitRails < Chef::Resource::PushitApp

      def initialize(name, run_context = nil)
        super

        @resource_name = :pushit_rails
        @provider = Chef::Provider::PushitRails
        @action = :create
        @allowed_actions = [:create]

        @framework = 'rails'
        @bundle_binary = nil
        @unicorn_binary = nil
      end

      def bundle_binary(arg = nil)
        set_or_return(
          :bundle_binary,
          arg,
          :kind_of => [String]
        )
      end

      def gems(arg = nil)
        set_or_return(
          :gems,
          arg,
          :kind_of => [Array],
          :default => %w{ bundler unicorn }
        )
      end

      def migrate(arg = nil)
        set_or_return(
          :migrate,
          arg,
          :kind_of => [TrueClass, FalseClass],
          :default => true
        )
      end

      def precompile_assets(arg = nil)
        set_or_return(
          :precompile_assets,
          arg,
          :kind_of => [TrueClass, FalseClass]
        )
      end

      def precompile_command(arg = nil)
        set_or_return(
          :precompile_command,
          arg,
          :kind_of => [String],
          :default => 'assets:precompile'
        )
      end

      def unicorn_binary(arg = nil)
        set_or_return(
          :unicorn_binary,
          arg,
          :kind_of => [String]
        )
      end

      def unicorn_enable_stats(arg = nil)
        set_or_return(
          :unicorn_enable_stats,
          arg,
          :kind_of => [TrueClass, FalseClass],
          :default => true
        )
      end

      def unicorn_listen_port(arg = nil)
        set_or_return(
          :unicorn_listen_port,
          arg,
          :kind_of => [Integer],
          :default => 8080
        )
      end

      def unicorn_listen_socket(arg = nil)
        set_or_return(
          :unicorn_listen_socket,
          arg,
          :kind_of => [String]
        )
      end

      def unicorn_preload_app(arg = nil)
        set_or_return(
          :unicorn_preload_app,
          arg,
          :kind_of => [TrueClass, FalseClass],
          :default => true
        )
      end

      def unicorn_worker_processes(arg = nil)
        set_or_return(
          :unicorn_worker_processes,
          arg,
          :kind_of => [Integer],
          :default => 1
        )
      end

      def unicorn_worker_timeout(arg = nil)
        set_or_return(
          :unicorn_worker_timeout,
          arg,
          :kind_of => [Integer],
          :default => 60
        )
      end
    end
  end
end
