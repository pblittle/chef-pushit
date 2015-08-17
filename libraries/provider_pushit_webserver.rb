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
    class PushitWebserver < Chef::Provider::LWRPBase
      use_inline_resources
      include Chef::DSL::IncludeRecipe

      def action_create
        include_recipe 'nginx::default'
        nginx_template = find_resource_safely('template[nginx.conf]')
        update_nginx_template(nginx_template)

        s = nginx_service
        s.action [:enable, :start]
      end

      def action_delete
        s = nginx_service
        s.action [:stop, :disable]
      end

      def action_restart
        action_create
        nginx_service.action :restart
      end

      def action_reload
        action_create
        nginx_service.action :reload
      end

      private

      def nginx_service
        service 'nginx' do
          action :nothing
          supports :restart => true, :reload => true, :status => true
          provider Chef::Provider::Service::Upstart
          only_if { ::File.exist?('/etc/init/nginx.conf') }
        end
      end

      def update_nginx_template(nginx_template)
        nginx_template.source new_resource.config_source
        nginx_template.cookbook new_resource.config_cookbook
        nginx_template.mode '0644'
        nginx_template.variables(
          :pid => node['nginx']['pid'],
          :log_dir => node['nginx']['log_dir'],
          :conf_dir => node['nginx']['dir']
        )
      end

      def sub_resources_updated?
        updated = false
        %w( template[/etc/init/nginx.conf]
            cookbook_file[#{node['nginx']['dir']}/mime.types]
            bash[compile_nginx_source]
            service[nginx]
        ).each do |name|
          resource = find_resource_safely name
          next unless resource

          resource = [resource] unless resource.is_a? Array
          resource.each { |r| updated ||= r.updated_by_last_action? }
        end
        updated
      end

      def find_resource_safely(name)
        run_context.resource_collection.find(name)
      rescue Chef::Exceptions::ResourceNotFound
        return nil
      end
    end
  end
end
