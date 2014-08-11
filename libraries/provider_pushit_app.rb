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

      def whyrun_supported?
        true # TODO: make sure that nodejs::install_from_source is kosher.
      end

      def action_create
        super

        recipe_eval do
          run_context.include_recipe 'nodejs::install_from_source'
        end

        gem_dependency_resources.each { |gem| gem.action :install }

        app_directory_resources.each { |dir| dir.action :create }

        if new_resource.framework == 'rails'
          shared_directory_resources.each { |dir| dir.action :create }

          pushit_ruby_resource.action :create
          ruby_version_file_resource.action :create

          if app.database
            database_config_resource.action :create
            filestore_config_resource.action :create
          end

          if app.webserver?
            unicorn_config_resource.action :create
          end
        end

        if app.database_certificate?
          ssl_cert_resource(app.database_certificate).action :create
        end

        if app.webserver?
          vhost_config_resource.action :create

          if app.webserver_certificate?
            ssl_cert_resource(app.webserver_certificate).action :create
          end
        end

        deploy_revision_resource.action new_resource.deploy_action
      end

      def deploy_revision_resource; end

      def before_migrate
        dotenv_file_resource.action :create
      end

      def before_symlink
        config_file_resources.each { |conf| conf.action :create }
      end

      def before_restart
        procfile_resource.action :create
        foreman_export_resource.action :run
        supervisor_resource.action :nothing
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

      def gem_dependency_resources
        PUSHIT_APP_GEM_DEPENDENCIES.map do |gem|
          chef_gem gem[:name] do
            version gem[:version] if gem[:version]
            action :nothing
          end
        end
      end

      def pushit_ruby_resource
        r = pushit_ruby ruby.version
        r.environment ruby.environment
        r.user user_username
        r.group user_group
        r.action :nothing
        r
      end

      def ruby_version_file_resource
        r = template ::File.join(app.shared_path, 'ruby-version')
        r.source 'ruby-version.erb'
        r.cookbook 'pushit'
        r.owner user_username
        r.group user_group
        r.mode '0644'
        r.variables(
          :ruby_version => ruby.version
        )
        r.action :nothing
        r
      end

      def app_directory_resources
        [app.path, app.shared_path].map do |dir|
          r = directory dir
          r.owner user_username
          r. group user_group
          r. recursive true
          r. mode 00755
          r.action :nothing
          r
        end
      end

      def shared_directory_resources
        app.shared_directories.map do |dir|
          r = directory ::File.join(app.shared_path, dir)
          r.owner user_username
          r.group user_group
          r.recursive true
          r.mode 00755
          r.action :nothing
          r
        end
      end

      def dotenv_file_resource
        r = template ::File.join(app.shared_path, 'env')
        r.source 'env.erb'
        r.cookbook 'pushit'
        r.owner user_username
        r.group user_group
        r.mode '0644'
        r.variables(
          :env => Pushit.escape_env(app.env_vars)
        )
        r.action :nothing
        r
      end

      def config_file_resources
        new_resource.config_files.map do |file|
          r = cookbook_file ::File.join(app.release_path, file)
          r.source file
          r.cookbook new_resource.cookbook_name.to_s
          r.owner user_username
          r.group user_group
          r.mode 00755
          r.action :nothing
          r
        end
      end

      def foreman_export_resource
        r = execute 'run foreman'
        r.command "#{app.foreman_binary} export #{app.foreman_export_flags}"
        r.cwd app.release_path
        r.user 'root'
        r.group 'root'
        r.action :nothing
        r
      end

      def supervisor_resource
        r = service new_resource.name
        r.provider Chef::Provider::Service::Upstart
        r.supports :status => true, :restart => true, :reload => true
        r.action :nothing
        r
      end

      def vhost_config_resource
        r = pushit_vhost new_resource.name
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
        r.action :nothing
        r
      end

      def ssl_cert_resource(certificate)
        r = certificate_manage certificate
        r.owner user_username
        r.group user_group
        r.cert_path Pushit::Certs.ssl_path
        r.cert_file "#{certificate}.pem"
        r.key_file "#{certificate}.key"
        r.chain_file "#{certificate}-bundle.crt"
        r.nginx_cert false
        r.action :nothing
        r
      end

      def procfile_resource
        r = file app.procfile
        r.content app.procfile_default_entry(new_resource.framework)
        r.owner user_username
        r.group user_group
        r.not_if { app.procfile? }
        r.action :nothing
        r
      end
    end
  end
end
