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

class Chef
  class Provider
    class PushitRuby < Chef::Provider

      def initialize(new_resource, run_context = nil)
        @new_resource = new_resource
        @run_context = run_context

        @run_context.include_recipe 'ruby_build'

        @dependencies = [ 'git::default' ]

        super(new_resource, run_context)
      end

      def load_current_resource; end

      def whyrun_supported?
        Pushit.whyrun_enabled?
      end

      def ruby
        @ruby ||= Pushit::Ruby.new(new_resource.name)
      end

      def action_create
        ruby_build_ruby new_resource.name do
          user 'deploy'
          group 'deploy'
          prefix_path ruby.prefix_path
          environment(new_resource.environment)
          not_if do
            ::File.exists?(::File.join(ruby.bin_path, 'ruby'))
          end
        end

        new_resource.gems.each do |gem|
          gem_package gem[:name] do
            gem_binary ::File.join(ruby.bin_path, 'gem')
            version gem[:version] if gem[:version]
          end
        end

        install_dependencies
        download_chruby
        install_chruby
        source_chruby

        new_resource.updated_by_last_action(true)
      end

      def install_dependencies
        recipe_eval do
          Pushit::App::Dependency.new(new_resource, run_context)
        end
      end

      def download_chruby
        ssh_known_hosts_entry 'github.com'

        source = Chef::Resource::Git.new(
          "#{Chef::Config[:file_cache_path]}/chruby",
          run_context
        )
        source.repository 'https://github.com/postmodern/chruby.git'
        source.reference 'v0.3.7'
        source.user 'root'
        source.group 'root'
        source.run_action(:sync)

        if source.updated_by_last_action?
          new_resource.updated_by_last_action(true)
        end
      end

      def install_chruby
        installer = Chef::Resource::Execute.new(
          'Install chruby',
          run_context
        )
        installer.command 'make install'
        installer.cwd "#{Chef::Config[:file_cache_path]}/chruby"
        installer.user 'root'
        # installer.environment({
        #   'share_path' => '/opt/pushit/chruby'
        # })
        installer.run_action(:run)

        if installer.updated_by_last_action?
          new_resource.updated_by_last_action(true)
        end
      end

      def source_chruby
        template '/etc/profile.d/chruby.sh' do
          source 'chruby.sh.erb'
          cookbook 'pushit'
          mode '0644'
          variables(
            :chruby_path => '/usr/local/share/chruby',
            :rubies_path => ruby.rubies_path,
            :default_ruby => new_resource.name
          )
        end
      end
    end
  end
end
