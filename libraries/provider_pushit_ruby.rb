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

require File.expand_path('../chef_pushit', __FILE__)
require File.expand_path('../provider_pushit_base', __FILE__)

class Chef
  class Provider

    class PushitRuby < Chef::Provider::PushitBase

      def initialize(new_resource, run_context = nil)
        @new_resource = new_resource
        @run_context = run_context
        # @run_context.node.default['rbenv']['user_installs'] = [{
        #   'user' => new_resource.user,
        #   'home' => user.home,
        #   'environment' => new_resource.environment
        # }]

        recipe_eval do
          @run_context.include_recipe('ruby_build::default')
        end

        recipe_eval do
          @run_context.include_recipe('rbenv::user_install')
        end

        super(new_resource, run_context)
      end

      def load_current_resource; end

      def whyrun_supported?
        Pushit.whyrun_enabled?
      end

      def action_create
        install_ruby
        rehash
        install_gems
      end

      def ruby
        @ruby ||= Pushit::Ruby.new(new_resource.name)
      end

      private

      def install_ruby
        r = ruby_build_ruby ruby.version do
          definition ruby.version
          prefix_path ruby.prefix_path
          environment(new_resource.environment)
          action :nothing
        end
        r.run_action(:install)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def rehash
        r = Chef::Resource::RbenvRehash.new(
          ruby.version,
          run_context
        )
        r.root_path ruby.rubies_path
        r.user @user.username

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def install_gems
        new_resource.gems.each do |gem|
          r = Chef::Resource::RbenvGem.new(
            gem[:name],
            run_context
          )
          r.rbenv_version ruby.version
          r.version gem[:version] if gem[:version]
          r.user @user.username

          new_resource.updated_by_last_action(true) if r.updated_by_last_action?
        end
      end
    end
  end
end
