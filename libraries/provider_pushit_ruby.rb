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
          prefix_path ruby.prefix_path
          environment(new_resource.environment)
          not_if do
            ::File.exists?(::File.join(ruby.bin_path, 'ruby'))
          end
        end

        new_resource.gems.each do |gem|
          gem_package gem do
            gem_binary ::File.join(ruby.bin_path, 'gem')
          end
        end

        template '/etc/profile.d/pushit_ruby.sh' do
          source 'pushit_ruby.sh.erb'
          cookbook 'pushit'
          mode '0755'
          variables(
            :ruby_build_bin_path => ruby.bin_path
          )
          notifies :run, "bash[source_ruby]", :immediately
        end

        bash 'source_ruby' do
          code <<-EOF
          echo 'source /etc/profile.d/pushit_ruby.sh' > .bashrc
          chmod +x /etc/profile.d/pushit_ruby.sh
          EOF
          cwd Pushit::User.home_path
          action :nothing
          not_if "egrep '/etc/profile.d/pushit_ruby.sh' .bashrc"
        end

        new_resource.updated_by_last_action(true)
      end
    end
  end
end
