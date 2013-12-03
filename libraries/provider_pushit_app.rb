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
          create_vhost_config
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

      def user
        @user ||= app.user
      end

      def escape_env(vars = {})
        vars.inject({}) do |hash, (key, value)|
          hash[key.upcase] = value.gsub(/"/) { %q(\") }
          hash
        end
      end

      def enable_and_start_service
        r = Chef::Resource::Service.new(
          new_resource.name,
          run_context
        )
        r.provider Chef::Provider::Service::Upstart
        r.supports :status => true, :restart => true
        r.run_action(:enable)
        r.run_action(:stop)
        r.run_action(:start)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_directories
        [app.path, app.shared_path].each do |dir|
          r = Chef::Resource::Directory.new(
            dir,
            run_context
          )
          r.owner Etc.getpwnam(user.username).uid
          r.group Etc.getgrnam(user.group).gid
          r.recursive true
          r.mode 00755
          r.run_action(:create)

          new_resource.updated_by_last_action(true) if r.updated_by_last_action?
        end
      end

      def create_shared_directories
        %w{ cached-copy config system vendor_bundle }.each do |dir|
          r = Chef::Resource::Directory.new(
            ::File.join(app.shared_path, dir),
            run_context
          )
          r.owner Etc.getpwnam(user.username).uid
          r.group Etc.getgrnam(user.group).gid
          r.recursive true
          r.mode 00755
          r.run_action(:create)

          new_resource.updated_by_last_action(true) if r.updated_by_last_action?
        end
      end

      def create_writable_directories
        %w{ log pids sockets }.each do |dir|
          r = Chef::Resource::Directory.new(
            ::File.join(app.shared_path, dir),
            run_context
          )
          r.owner Etc.getpwnam(user.username).uid
          r.group Etc.getgrnam(user.group).gid
          r.recursive true
          r.mode 00755
          r.run_action(:create)

          new_resource.updated_by_last_action(true) if r.updated_by_last_action?

          execute "chmod -R 00755 #{::File.join(app.shared_path, dir)}"
        end
      end

      def create_vhost_config
        r = Chef::Resource::PushitVhost.new(
          new_resource.name,
          run_context
        )
        r.config_type new_resource.framework
        r.http_port 80
        r.server_name '_'
        r.upstream_port 8080
        r.upstream_socket app.upstream_socket
        r.use_ssl true
        r.run_action(:create)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_monit_check
        r = Chef::Resource::PushitMonit.new(
          new_resource.name,
          run_context
        )
        r.check({
          :name => new_resource.name,
          :pid_file => app.upstart_pid,
          :start_program => "/sbin/start #{new_resource.name}",
          :stop_program => "/sbin/stop #{new_resource.name}",
          :uid => 'root',
          :gid => 'root'
        })
        r.run_action(:install)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end
    end
  end
end
