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
      # This gives us access to the `lazy` method for delayed attribute evaluation
      # without it, we'd need to set attributes inside a resource block, rather than
      # with the r.attribute syntax.
      include Chef::Mixin::ParamsValidate
      use_inline_resources if defined?(use_inline_resources)

      def whyrun_supported?
        false # TODO: make sure that nodejs::install_from_source is kosher, and need to deal with unknown release dir
      end

      def action_create
        super

        add_pre_app_directory_resources

        app_directory_resources.each { |dir| dir.action :create }

        add_after_app_directory_resources

        add_pre_deploy_resources

        converge_by 'deploy the new app' do
          r = deploy_resource
          r.action new_resource.deploy_action
          customize_deploy_revision_resource(r)
        end

        add_post_deploy_resources
      end

      def add_pre_app_directory_resources
        recipe_eval do
          run_context.include_recipe 'nodejs::install_from_source'
        end

        gem_dependency_resources.each do |gem|
          gem.action :install
          gem.notifies :restart, "service[#{new_resource.name}]"
        end
      end

      def add_after_app_directory_resources; end

      def add_pre_deploy_resources
        dotenv_file_resource.action :create

        return unless app.webserver?
        vhost_config_resource.action :create
      end

      def deploy_resource
        app_provider = self

        username = user_username
        group = user_group
        ssh_directory = user_ssh_directory

        app_local = app
        r = deploy_revision new_resource.name
        r.action :nothing
        r.deploy_to app_local.path

        r.repository config['repo']
        r.revision new_resource.revision
        r.shallow_clone true

        if config['deploy_key'] && !config['deploy_key'].empty?
          wrapper = "#{config['deploy_key']}_deploy_wrapper.sh"
          wrapper_path = ::File.join(ssh_directory, wrapper)

          r.ssh_wrapper wrapper_path
        end

        r.environment app_local.env_vars

        r.user username
        r.group group

        r.symlink_before_migrate(new_resource.symlink_before_migrate)

        r.before_symlink { app_provider.send(:before_symlink) }

        r.notifies :restart, "service[#{new_resource.name}]"
        r
      end

      def customize_deploy_revision_resource(_deploy_resource); end

      def before_migrate; end

      def before_symlink; end

      def before_restart; end

      def add_post_deploy_resources
        # TODO: NONE OF THESE support why_run unless we do something about the revision dir.
        config_file_resources.each do |conf|
          conf.action :create
          conf.notifies :restart, "service[#{new_resource.name}]"
        end

        procfile_resource.action :create
        foreman_export_resource.action :run
        service_resource.action [:enable, :start]
      end

      # TODO: what methods can be protected and/or private?

      protected

      def app
        @app ||= Pushit::App.new(new_resource.name, new_resource.config)
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

      def dotenv_file_resource
        app_local = app
        r = template ::File.join(app_local.shared_path, 'env')
        r.source 'env.erb'
        r.cookbook 'pushit'
        r.owner user_username
        r.group user_group
        r.mode '0644'
        r.variables(
          :env => Pushit.escape_env(app_local.env_vars.sort)
        )
        r.action :nothing
        r
      end

      def config_file_resources
        app_local = app
        new_resource.config_files.map do |file|
          r = cookbook_file "#{app_local.name}'s #{file} file"
          r.path lazy { ::File.join(app_local.release_path, file) }
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
        app_local = app
        r = foreman_export app_local.name
        r.format :upstart
        r.log app_local.log_path
        r.user app_local.config['owner']
        r.env lazy { app_local.envfile }
        r.root lazy { app_local.release_path }
        r.pid_dir app_local.pid_path
        r.location '/etc/init'
        r.notifies :restart, "service[#{new_resource.name}]"
        r
      end

      def service_resource
        app_local = app
        r = service new_resource.name
        r.provider Chef::Provider::Service::Upstart
        r.supports :status => true, :restart => false, :reload => false
        r.only_if { ::File.exist? "/etc/init/#{app_local.name}.conf" }
        r.action :nothing
        r
      end

      def vhost_config_resource
        app_local = app
        r = pushit_vhost new_resource.name
        r.http_port app_local.http_port
        r.https_port app_local.https_port
        r.server_name app_local.server_name
        r.upstream_port app_local.upstream_port
        r.upstream_socket app_local.upstream_socket
        r.use_ssl app_local.webserver_certificate?
        r.ssl_certificate app_local.webserver_certificate
        r.config_cookbook new_resource.vhost_config_cookbook
        r.config_source new_resource.vhost_config_source || "nginx_#{new_resource.framework}.conf.erb"
        r.config_variables new_resource.vhost_config_variables || {}
        r.nginx_config_cookbook new_resource.nginx_config_cookbook
        r.nginx_config_source new_resource.nginx_config_source
        r.nginx_config_variables new_resource.nginx_config_variables || {}
        r.root app_local.root
        r.action :nothing
        r
      end

      def procfile_resource
        app_local = app
        r = file "#{app_local.name} Procfile"
        r.path lazy { app_local.procfile }
        r.content app.procfile_default_entry(new_resource.framework)
        r.owner user_username
        r.group user_group
        r.not_if { app_local.procfile? }
        r.action :nothing
        r
      end
    end
  end
end
