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

    class PushitRuby < Chef::Provider::PushitBase

      def initialize(new_resource, run_context = nil)
        @new_resource = new_resource
        @run_context = run_context

        recipe_eval do
          @run_context.include_recipe('ruby_build::default')
        end

        super(new_resource, run_context)
      end

      def load_current_resource; end

      def whyrun_supported?
        Pushit.whyrun_enabled?
      end

      def action_create
        install_ruby

        download_chruby
        install_chruby
        create_chruby_sh

        install_gems
      end

      def ruby
        @ruby ||= Pushit::Ruby.new(
          'version' => new_resource.name,
          'environment' => new_resource.environment
        )
      end

      private

      def install_ruby
        r = ruby_build_ruby new_resource.name do
          definition new_resource.name
          prefix_path ruby.prefix_path
          environment(new_resource.environment)
          action :nothing
        end
        r.run_action(:install)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def download_chruby
        ssh_known_hosts_entry 'github.com'

        r = Chef::Resource::Git.new(
          "#{Chef::Config[:file_cache_path]}/chruby",
          run_context
        )
        r.repository 'https://github.com/postmodern/chruby.git'
        r.reference 'v0.3.8'
        r.user 'root'
        r.group 'root'
        r.run_action(:sync)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def install_chruby
        r = Chef::Resource::Execute.new(
          'Install chruby',
          run_context
        )
        r.command 'make install'
        r.cwd "#{Chef::Config[:file_cache_path]}/chruby"
        r.user 'root'
        r.run_action(:run)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_chruby_sh
        r = template '/etc/profile.d/chruby.sh' do
          source 'chruby.sh.erb'
          cookbook 'pushit'
          mode '0644'
          variables(
            :chruby_path => '/usr/local/share/chruby',
            :rubies_path => ruby.rubies_path,
            :default_ruby => new_resource.name
          )
          action :nothing
        end
        r.run_action(:create)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end
    end

    def install_gems
      [{ :name => 'bundler' }].each do |gem|
        r = gem_package gem[:name] do
          version gem[:version] if gem[:version]
          gem_binary ruby.gem_binary
          options('--no-ri --no-rdoc')
          action :nothing
        end
        r.run_action(:install)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end
    end
  end
end
