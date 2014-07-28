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
    # Base class for building an app. This class should
    # not be implemented outside of subclass inheritance.
    class PushitApp < Chef::Provider::PushitBase

      use_inline_resources if defined?(use_inline_resources)

      def action_create
        super

        recipe_eval do
          run_context.include_recipe 'nodejs::install_from_source'
          run_context.include_recipe 'runit::default'
        end

        install_gem_dependencies

        create_directories

        if new_resource.framework == 'rails'
          create_shared_directories

          pushit_ruby.run_action(:create)
          ruby_version.run_action(:create)

          if app.database
            database_config.run_action(:create)
            filestore_config.run_action(:create)
          end

          if app.webserver?
            unicorn_config.run_action(:create)
          end
        end

        if app.database_certificate?
          ssl_cert(app.database_certificate).run_action(:create)
        end

        if app.webserver?
          vhost_config.run_action(:create)

          if app.webserver_certificate?
            ssl_cert(app.webserver_certificate).run_action(:create)
          end
        end

        deploy_revision.run_action(new_resource.deploy_action)
      end

      def deploy_revision; end

      def before_migrate
        dotenv.run_action(:create)
      end

      def before_symlink
        create_config_files
      end

      def before_restart
        procfile.run_action(:create)
        foreman_export.run_action(:run)
        runit_service.run_action(:start)
      end

      def after_restart; end

      protected

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

      def user_username
        @user_username ||= user.username
      end

      def user_group
        @user_group ||= user.group
      end

      def user_ssh_directory
        @user_ssh_directory ||= user.ssh_directory
      end

      def install_gem_dependencies
        PUSHIT_APP_GEM_DEPENDENCIES.each do |gem|
          r = chef_gem gem[:name] do
            version gem[:version] if gem[:version]
            action :nothing
          end
          r.run_action(:install)
        end
      end

      def pushit_ruby
        r = Chef::Resource::PushitRuby.new(
          ruby.version,
          run_context
        )
        r.environment ruby.environment
        r.user user_username
        r.group user_group
        r
      end

      def ruby_version
        r = Chef::Resource::Template.new(
          ::File.join(app.shared_path, 'ruby-version'),
          run_context
        )
        r.source 'ruby-version.erb'
        r.cookbook 'pushit'
        r.owner user_username
        r.group user_group
        r.mode '0644'
        r.variables(
          :ruby_version => ruby.version
        )
        r
      end

      def create_directories
        [app.path, app.shared_path].each do |dir|
          r = Chef::Resource::Directory.new(
            dir,
            run_context
          )
          r.owner user_username
          r.group user_group
          r.recursive true
          r.mode 00755
          r.run_action(:create)
        end
      end

      def create_shared_directories
        app.shared_directories.each do |dir|
          r = Chef::Resource::Directory.new(
            ::File.join(app.shared_path, dir),
            run_context
          )
          r.owner user_username
          r.group user_group
          r.recursive true
          r.mode 00755
          r.run_action(:create)
        end
      end

      def dotenv
        r = Chef::Resource::Template.new(
          ::File.join(app.shared_path, 'env'),
          run_context
        )
        r.source 'env.erb'
        r.cookbook 'pushit'
        r.owner user_username
        r.group user_group
        r.mode '0644'
        r.variables(
          :env => Pushit.escape_env(app.env_vars)
        )
        r
      end

      def create_config_files
        new_resource.config_files.each do |file|
          r = Chef::Resource::CookbookFile.new(
            ::File.join(app.release_path, file),
            run_context
          )
          r.source file
          r.cookbook new_resource.cookbook_name.to_s
          r.owner user_username
          r.group user_group
          r.mode 00755
          r.run_action(:create)
        end
      end

      def foreman_export
        r = Chef::Resource::Execute.new(
          "#{app.foreman_binary} export #{app.foreman_export_flags}",
          run_context
        )
        r.cwd app.release_path
        r.user user_username
        r.group user_group
        r
      end

      def runit_service
        r = Chef::Resource::RunitService.new(
          new_resource.name,
          run_context
        )
        r.sv_dir app.runit_sv_path
        r.service_dir app.runit_service_path
        r.check false
        r.log false
        r.sv_templates false
        r.owner user_username
        r.group user_group
        r
      end

      def vhost_config
        r = Chef::Resource::PushitVhost.new(
          new_resource.name,
          run_context
        )
        r.http_port app.http_port
        r.https_port app.https_port
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
        r.config_cookbook new_resource.vhost_config_cookbook
        r.config_source new_resource.vhost_config_source || "nginx_#{new_resource.framework}.conf.erb"
        r
      end

      def ssl_cert(certificate)
        r = Chef::Resource::CertificateManage.new(
          certificate,
          run_context
        )
        r.owner user_username
        r.group user_group
        r.cert_path Pushit::Certs.ssl_path
        r.cert_file "#{certificate}.pem"
        r.key_file "#{certificate}.key"
        r.chain_file "#{certificate}-bundle.crt"
        r.nginx_cert false
        r
      end

      def procfile
        r = Chef::Resource::File.new(
          app.procfile,
          run_context
        )
        r.content app.procfile_default_entry(new_resource.framework)
        r.owner user_username
        r.group user_group
        r.not_if { app.procfile? }
        r
      end
    end
  end
end
