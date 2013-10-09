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

require File.expand_path('../chef_pushit', __FILE__)
require File.expand_path('../provider_pushit_base', __FILE__)
require File.expand_path('../provider_pushit_monit', __FILE__)

class Chef
  class Provider
    class PushitApp < Chef::Provider::PushitBase

      def initialize(new_resource, run_context = nil)
        @new_resource = new_resource
        @run_context = run_context

        super(new_resource, run_context)
      end

      def load_current_resource; end

      def whyrun_supported?
        Pushit.whyrun_enabled?
      end

      def action_create
        create_directories

        if new_resource.framework == 'rails'
          create_shared_directories
          create_dotenv
          create_ruby_version
          create_database_yaml
          create_unicorn_config
        end

        create_writable_directories
        create_deploy_revision
        create_service_config
        create_monit_check
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
          hash[key.upcase] = value.gsub(/"/) { %q(\") }
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

        if service.updated_by_last_action?
          new_resource.updated_by_last_action(true)
        end
      end

      def create_directories
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

          if dir.updated_by_last_action?
            new_resource.updated_by_last_action(true)
          end
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

          if dir.updated_by_last_action?
            new_resource.updated_by_last_action(true)
          end
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

          if dir.updated_by_last_action?
            new_resource.updated_by_last_action(true)
          end

          execute "chmod -R 00755 #{::File.join(app.shared_path, shared_dir)}"
        end
      end

      def create_monit_check
        config = Chef::Resource::PushitMonit.new(
          new_resource.name,
          run_context
        )
        config.check({
          :name => new_resource.name,
          :pid_file => "#{app.shared_path}/pids/upstart.pid",
          :start_program => "/sbin/start #{new_resource.name}",
          :stop_program => "/sbin/stop #{new_resource.name}",
          :uid => 'root',
          :gid => 'root'
        })
        config.run_action(:install)

        if config.updated_by_last_action?
          new_resource.updated_by_last_action(true)
        end
      end
    end
  end
end
