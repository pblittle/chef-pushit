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
          create_ruby_version
          create_database_yaml
          create_unicorn_config
        end

        create_dotenv
        create_deploy_revision

        if app.has_webserver?
          create_ssl_cert if app.use_ssl?
          create_vhost_config
        end

        create_service_config
        create_logrotate_config

        enable_and_start_service
      end

      def before_symlink
        create_writable_directories
        create_config_files
      end

      def after_restart
        # create_newrelic_notification
        # create_campfire_notification(:announce_success)
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
        r.supports :status => true, :restart => true, :reload => true
        r.restart_command(
          "stop #{new_resource.name} && start #{new_resource.name}"
        )
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

      def create_config_files
        new_resource.config_files.each do |file|
          r = Chef::Resource::CookbookFile.new(
            ::File.join(app.release_path, file),
            run_context
          )
          r.source file
          r.cookbook new_resource.cookbook_name
          r.owner Etc.getpwnam(user.username).uid
          r.group Etc.getgrnam(user.group).gid
          r.mode 00755
          r.run_action(:create)

          new_resource.updated_by_last_action(true) if r.updated_by_last_action?
        end
      end

      def create_logrotate_config
        # r = Chef::Resource::LogrotateApp.new(
        #   app.log_path,
        #   run_context
        # )
        # r.template_owner Etc.getpwnam(user.username).uid
        # r.template_group Etc.getgrnam(user.group).gid
        # r.run_action(:create)

        # new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_vhost_config
        r = Chef::Resource::PushitVhost.new(
          new_resource.name,
          run_context
        )
        r.config_type new_resource.framework
        r.http_port app.http_port
        r.server_name app.server_name
        r.upstream_port app.upstream_port
        r.upstream_socket app.upstream_socket
        r.use_ssl app.use_ssl?
        r.ssl_certificate ::File.join(
          Pushit::Certs.certs_path, 'certs', "#{new_resource.name}-bundle.crt"
        )
        r.ssl_certificate_key ::File.join(
          Pushit::Certs.certs_path, 'private', "#{new_resource.name}.key"
        )
        r.run_action(:create)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_ssl_cert
        r = Chef::Resource::CertificateManage.new(
          new_resource.name,
          run_context
        )
        r.owner 'root' # Etc.getpwnam(app.config['owner']).name
        r.group 'root' # Etc.getgrnam(app.config['group']).name
        r.cert_path Pushit::Certs.certs_path
        r.cert_file "#{new_resource.name}.pem"
        r.key_file "#{new_resource.name}.key"
        r.chain_file "#{new_resource.name}-bundle.crt"
        r.nginx_cert false
        r.run_action(:create)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_newrelic_notification
        r = Chef::Resource::NewrelicDeployment.new(
          app.config['env']['NEW_RELIC_APP_NAME'],
          run_context
        )
        r.api_key app.config['env']['NEW_RELIC_API_KEY']
        r.revision app.version
        r.user app.config['owner']
        r.run_action(:create)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_campfire_notification(action = :announce_start)
        r = Chef::Resource::CampfireDeployment.new(
          new_resource.name,
          run_context
        )
        r.account app.config['env']['CAMPFIRE_DEPLOYMENT_ACCOUNT']
        r.token app.config['env']['CAMPFIRE_DEPLOYMENT_TOKEN']
        r.room app.config['env']['CAMPFIRE_DEPLOYMENT_ROOM']
        r.release({
          deployer: user.username,
          environment: new_resource.environment,
          revision: new_resource.revision,
          application: new_resource.name
        })
        r.run_action(action)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end
    end
  end
end
