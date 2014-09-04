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
    # Provider for installing a ruby in the pushit rubies directory
    class PushitRuby < Chef::Provider::PushitBase
      use_inline_resources if defined?(use_inline_resources)

      def whyrun_supported?
        true
      end

      def action_create
        super

        recipe_eval do
          @run_context.include_recipe('ruby_build::default')
        end

        ruby_build_resource.action :install

        chruby_source_resource.action :sync
        chruby_install_resource.action :run
        chruby_sh_resource.action :create
        bundler_gem_resource.action :install
      end

      def ruby
        @ruby ||= Pushit::Ruby.new(
          'version' => new_resource.name,
          'environment' => new_resource.environment,
          'bundler_version' => new_resource.bundler_version
        )
      end

      private

      def ruby_build_resource
        ruby_build_ruby new_resource.name do
          definition new_resource.name
          prefix_path ruby.prefix_path
          environment(new_resource.environment)
          action :nothing
        end
      end

      def chruby_source_resource
        ssh_known_hosts_entry 'github.com'

        git "#{Chef::Config[:file_cache_path]}/chruby" do
          repository 'https://github.com/postmodern/chruby.git'
          reference "v#{node['pushit']['chruby']['version']}"
          user 'root'
          group 'root'
          action :nothing
          not_if "chruby --version | grep -F #{node['pushit']['chruby']['version']}"
        end
      end

      def chruby_install_resource
        execute 'Install chruby' do
          command 'make install'
          cwd "#{Chef::Config[:file_cache_path]}/chruby"
          user 'root'
          action :nothing
          not_if "chruby --version | grep -F #{node['pushit']['chruby']['version']}"
        end
      end

      def chruby_sh_resource
        template '/etc/profile.d/chruby.sh' do
          source 'chruby.sh.erb'
          cookbook 'pushit'
          mode '0755'
          variables(
            :chruby_path => '/usr/local/share/chruby',
            :rubies_path => ruby.rubies_path,
            :default_ruby => new_resource.name
          )
          action :nothing
        end
      end

      def bundler_gem_resource
        gem_package 'bundler' do
          version ruby.bundler_version
          gem_binary ruby.gem_binary
          options('--no-ri --no-rdoc')
          action :nothing
        end
      end
    end
  end
end
