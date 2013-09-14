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

require 'chef/mixin/command'
require 'chef/provider'

class Chef
  class Provider
    class PushitApp < Chef::Provider

      include Chef::Mixin::ShellOut

      attr_accessor :app, :config

      def initialize(new_resource, run_context = nil)
        @app = Pushit::App.new(new_resource.name)
        @config = nil

        super(new_resource, run_context)
      end

      def load_current_resource; end

      def whyrun_supported?
        Pushit.whyrun_enabled?
      end

      def action_create
        install_app_dependencies
        create_app_directories

        if new_resource.framework == 'rails'
          create_shared_directories
          create_dotenv
          create_dotruby
          create_database_yaml
        end

        create_writable_directories
        create_deploy_revision

        create_service_config
        enable_and_start_service

        new_resource.updated_by_last_action(true)
      end

      private

      def app
        @app ||= Pushit::App.new(new_resource.name)
      end

      def config
        @config ||= app.config
      end

      def escape_env(vars = {})
        vars.inject({}) do |hash, (key, value)|
          hash[key.upcase] = value.gsub(/"/){ %q(\") }
          hash
        end
      end

      def enable_and_start_service
        service = Chef::Resource::Service.new(
          new_resource.name,
          run_context
        )
        service.provider Chef::Provider::Service::Upstart
        service.supports :status => true, :restart => true
        service.run_action(:enable)
        service.run_action(:start)
      end

      def install_app_dependencies
        recipe_eval do
          Pushit::App::Dependency.new(new_resource, run_context)
        end
      end

      def create_app_directories
        Chef::Log.debug("Creating app directories for #{new_resource.name}")

        [app.path, app.shared_path].each do |app_dir|
          dir = Chef::Resource::Directory.new(
            app_dir,
            run_context
          )
          dir.owner Etc.getpwnam(config['owner']).uid
          dir.group Etc.getpwnam(config['owner']).gid
          dir.recursive true
          dir.mode 00755
          dir.run_action(:create)
        end
      end

      def create_shared_directories
        Chef::Log.debug("Creating shared directories for #{new_resource.name}")

        %w{ cached-copy config system vendor_bundle }.each do |dir|
          dir = Chef::Resource::Directory.new(
            ::File.join(app.shared_path, dir),
            run_context
          )
          dir.owner Etc.getpwnam(config['owner']).uid
          dir.group Etc.getgrnam(config['group']).gid
          dir.recursive true
          dir.mode 00755
          dir.run_action(:create)
        end
      end

      def create_writable_directories
        Chef::Log.debug("Creating writable directories for #{new_resource.name}")

        %w{ log pids }.each do |shared_dir|
          dir = Chef::Resource::Directory.new(
            ::File.join(app.shared_path, shared_dir),
            run_context
          )
          dir.owner Etc.getpwnam(config['owner']).uid
          dir.group Etc.getgrnam(config['group']).gid
          dir.recursive true
          dir.mode 00755
          dir.run_action(:create)

          execute "chmod -R 00755 #{::File.join(app.shared_path, shared_dir)}"
        end
      end
    end
  end
end
