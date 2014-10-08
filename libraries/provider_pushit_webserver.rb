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
    # provider for creating a webserver for pushit apps
    class PushitWebserver < Chef::Provider::PushitBase
      use_inline_resources if defined?(use_inline_resources)

      def action_create
        super

        node.normal['nginx']['log_dir'] = new_resource.log_dir
        node.normal['nginx']['pid'] = new_resource.pid_file
        node.normal['nginx']['dir'] = new_resource.config_path

        recipe_eval do
          run_context.include_recipe 'nginx::default'
          update_nginx_template_resource
        end

        update_nginx_template_resource

        service 'nginx' do
          action :start
        end
      end

      def action_delete
        super

        service 'nginx' do
          action :stop
        end

        # TODO: how do we delete the config (or do we)
      end

      def action_restart
        action_create
        service 'nginx' do
          action :restart
        end
      end

      def action_reload
        action_create
        service 'nginx' do
          action :reload
        end
      end

      def update_nginx_template_resource
        begin
          nginx_template = run_context.resource_collection.find('template[nginx.conf]')

          nginx_template.source 'nginx.conf.erb'
          nginx_template.cookbook 'pushit'
          nginx_template.owner node.normal['nginx']['user'] = new_resource.user
          nginx_template.group node.normal['nginx']['group'] = new_resource.group
          nginx_template.mode '0644'
          nginx_template.variables(
            :log_dir => new_resource.log_dir,
            :pid_file => new_resource.pid_file,
            :config_path => new_resource.config_path
          )
        rescue Chef::Exceptions::ResourceNotFound
        end
      end
    end
  end
end
