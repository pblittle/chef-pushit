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

require ::File.expand_path('../chef_pushit', __FILE__)
require ::File.expand_path('../provider_pushit_base', __FILE__)

class Chef
  class Provider
    class PushitApp < Chef::Provider::PushitBase

      def initialize(new_resource, run_context = nil)
        @new_resource = new_resource
        @run_context = run_context

        @run_context.include_recipe('campfire-deployment::default')
        @run_context.include_recipe('newrelic-deployment::default')
        @run_context.include_recipe('logrotate::global')

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

          create_database_config if @app.database?
          create_unicorn_config if @app.webserver?
        end

        install_ruby
        create_ruby_version

        create_ssl_cert(app.database_certificate) if app.database_certificate?
        create_ssl_cert(app.webserver_certificate) if app.webserver_certificate?

        create_vhost_config if app.webserver?

        create_logrotate_config
        create_monit_check

        create_dotenv
        create_deploy_revision
      end

      def create_deploy_revision; end

      def before_migrate; end

      def before_symlink
        create_writable_directories
        create_config_files
      end

      def before_restart
        create_service_config
        service_perform_action
      end

      def after_restart
        create_newrelic_notification
        # create_campfire_notification(:announce_success)
      end

      private

      def app
        @app ||= Pushit::App.new(new_resource.name)
      end

      def config
        @config ||= app.config
      end

      def ruby
        @ruby ||= begin
          Pushit::Ruby.new(config['ruby'])
        rescue
          Pushit::Ruby.new
        end
      end

      def user
        @user ||= app.user
      end

      def install_ruby
        r = Chef::Resource::PushitRuby.new(
          ruby.version,
          run_context
        )
        r.environment ruby.environment
        r.user user.username
        r.group user.group
        r.run_action(:create)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_ruby_version
        r = Chef::Resource::Template.new(
          ::File.join(app.shared_path, 'ruby-version'),
          run_context
        )
        r.source 'ruby-version.erb'
        r.cookbook 'pushit'
        r.owner user.username
        r.group user.group
        r.mode '0644'
        r.variables(
          :ruby_version => ruby.version
        )
        r.run_action(:create)

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

      def create_dotenv
        r = Chef::Resource::Template.new(
          ::File.join(app.shared_path, 'env'),
          run_context
        )
        r.source 'env.erb'
        r.cookbook 'pushit'
        r.owner config['owner']
        r.group config['group']
        r.mode '0644'
        r.variables(
           :env => escape_env(app.env_vars)
        )
        r.run_action(:create)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_config_files
        new_resource.config_files.each do |file|
          r = Chef::Resource::CookbookFile.new(
            ::File.join(app.release_path, file),
            run_context
          )
          r.source file
          r.cookbook new_resource.cookbook_name.to_s
          r.owner Etc.getpwnam(user.username).uid
          r.group Etc.getgrnam(user.group).gid
          r.mode 00755
          r.run_action(:create)

          new_resource.updated_by_last_action(true) if r.updated_by_last_action?
        end
      end

      def create_service_config
        if app.procfile?
          foreman_export_service_config
        else
          export_upstart_config
        end
      end

      def foreman_export_service_config
        r = Chef::Resource::Execute.new(
          "#{ruby.foreman_binary} export #{app.foreman_export_flags}",
          run_context
        )
        r.cwd app.release_path
        r.user 'root'
        r.group 'root'
        r.run_action :run
        r.notifies(
          :restart,
          "service[#{new_resource.name}]",
          :delayed
        )

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def service_perform_action
        r = Chef::Resource::Service.new(
          new_resource.name,
          run_context
        )
        r.provider Chef::Provider::Service::Upstart
        r.supports :status => true, :restart => true, :reload => true
        r.run_action :nothing

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_monit_check
        r = Chef::Resource::PushitMonit.new(
          new_resource.name,
          run_context
        )
        r.check(
          :name => new_resource.name,
          :pid_file => app.upstart_pid,
          :start_program => "/sbin/start #{new_resource.name}",
          :stop_program => "/sbin/stop #{new_resource.name}",
          :uid => 'root',
          :gid => 'root'
        )
        r.run_action(:install)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_logrotate_config
        log_path = app.log_path
        name = app.name
        username = user.username
        group = user.group

        logrotate_app name do
          cookbook 'logrotate'
          path log_path
          frequency 'daily'
          rotate 180
          options %w{ missingok dateext delaycompress notifempty compress }
          create "644 #{username} #{group}"
        end
      end

      def create_vhost_config
        r = Chef::Resource::PushitVhost.new(
          new_resource.name,
          run_context
        )
        r.http_port app.http_port
        r.server_name app.server_name
        r.upstream_port app.upstream_port
        r.upstream_socket app.upstream_socket
        r.use_ssl app.webserver_certificate?
        r.ssl_certificate ::File.join(
          Pushit::Certs.certs_directory,
          "#{app.webserver_certificate}-bundle.crt"
        )
        r.ssl_certificate_key ::File.join(
          Pushit::Certs.keys_directory,
          "#{app.webserver_certificate}.key"
        )
        r.config_cookbook new_resource.vhost_config_cookbook if new_resource.vhost_config_cookbook
        r.config_source new_resource.vhost_config_source if new_resource.vhost_config_source
        r.run_action(:create)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_ssl_cert(certificate)
        r = Chef::Resource::CertificateManage.new(
          certificate,
          run_context
        )
        r.owner user.username
        r.group user.group
        r.cert_path Pushit::Certs.ssl_path
        r.cert_file "#{certificate}.pem"
        r.key_file "#{certificate}.key"
        r.chain_file "#{certificate}-bundle.crt"
        r.nginx_cert false
        r.run_action(:create)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_newrelic_notification
        r = Chef::Resource::NewrelicDeployment.new(
          config['env']['NEW_RELIC_APP_NAME'],
          run_context
        )
        r.api_key config['env']['NEW_RELIC_API_KEY']
        r.revision app.version
        r.user config['owner']
        r.action(:create)
        r.only_if do
          (config.key?('env') &&
           config['env'].key?('NEW_RELIC_API_KEY') &&
           config['env'].key?('NEW_RELIC_APP_NAME')) &&
            app.environment != 'test'
        end

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_campfire_notification(action = :announce_start)
        r = Chef::Resource::CampfireDeployment.new(
          new_resource.name,
          run_context
        )
        r.account config['env']['CAMPFIRE_DEPLOYMENT_ACCOUNT']
        r.token config['env']['CAMPFIRE_DEPLOYMENT_TOKEN']
        r.room config['env']['CAMPFIRE_DEPLOYMENT_ROOM']
        r.release(
          deployer: user.username,
          environment: new_resource.environment,
          revision: new_resource.revision,
          application: new_resource.name
        )
        r.run_action(action)
        r.not_if do
          app.environment == 'test'
        end

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def escape_env(vars = {})
        vars.inject({}) do |hash, (key, value)|
          hash[key.upcase] = value.gsub(/"/) { %q(\") }
          hash
        end
      end
    end
  end
end
