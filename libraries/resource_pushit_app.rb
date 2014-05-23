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
    class PushitApp < Chef::Resource

      def initialize(name, run_context = nil)
        super

        @resource_name = :pushit_app
        @provider = Chef::Provider::PushitApp
        @action = :create
        @allowed_actions = [:create]

        @framework = nil
      end

      def name(arg = nil)
        set_or_return(
          :name,
          arg,
          :kind_of => [String],
          :required => true,
          :name_attribute => true,
          :regex => /^[a-z0-9\-_]+$/
        )
      end

      def framework(arg = nil)
        set_or_return(
          :framework,
          arg,
          :kind_of => [String],
          :required => true,
          :equal_to => %w{ nodejs rails }
        )
      end

      def deploy_action(arg = nil)
        set_or_return(
          :deploy_action,
          arg,
          :kind_of => [String],
          :default => 'deploy'
        )
      end

      def environment(arg = nil)
        set_or_return(
          :environment,
          arg,
          :kind_of => [String],
          :required => true,
          :default => 'development'
        )
      end

      def revision(arg = nil)
        set_or_return(
          :revision,
          arg,
          :kind_of => [String],
          :default => 'HEAD'
        )
      end

      def config_files(arg = nil)
        set_or_return(
          :config_files,
          arg,
          :kind_of => [Array],
          :default => []
        )
      end

      def vhost_config_source(arg = nil)
        set_or_return(
          :vhost_config_source,
          arg,
          :kind_of => String
        )
      end

      def vhost_config_cookbook(arg = nil)
        set_or_return(
          :vhost_config_cookbook,
          arg,
          :kind_of => String
        )
      end
    end
  end
end
