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

require_relative 'provider_pushit_app'

class Chef
  class Provider
    # Convenience class for using the app resource with
    # the rails framework (provider)
    class PushitRails < Chef::Provider::PushitApp
      use_inline_resources

      def whyrun_supported?
        true
      end

      def action_create
        super
      end

      private

      def add_after_app_directory_resources
        super
        shared_directory_resources.each { |dir| dir.action :create }

        pushit_ruby_resource.action :create
        ruby_version_file_resource.action :create

        if app.database
          database_config_resource.action :create
          ssl_cert_resource(app.database_certificate).action(:create) if app.database_certificate?

          filestore_config_resource.action :create
        end

        unicorn_config_resource.action :create if app.webserver?
      end

      def customize_deploy_revision_resource(r)
        app_provider = self
        r.migrate new_resource.migrate
        r.migration_command "#{app.bundle_binary} exec rake db:migrate"

        r.before_migrate do
          app_provider.send(:before_migrate)
          app_provider.send(:bundle_install, release_path)
        end
        r
      end

      # We have to build the command inside the ruby block because `app.release_path` isn't available
      # at resource collection time.  This also means we need a local variable that gets us access to `app`
      def add_post_deploy_resources
        if new_resource.precompile_assets
          app_local = app
          ruby_block 'precompile assests' do
            block do
              begin
                require 'bundler'
                app = app_local
                bundle_precompile_command = "sudo su - #{user_username} -c 'cd #{app.release_path} && source ./.env && #{app.bundle_binary} exec rake #{new_resource.precompile_command}'"
                Bundler.clean_system(bundle_precompile_command)
              rescue => e
                Chef::Log.warn e.backtrace
              end
            end
            action :nothing
            subscribes :run, "deploy_revision[#{new_resource.name}]", :immediate
          end
        end

        super
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

      def pushit_ruby_resource
        r = pushit_ruby ruby.version
        r.environment ruby.environment
        r.user user_username
        r.group user_group
        r.notifies :restart, "service[#{new_resource.name}]"
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
        r.notifies :restart, "service[#{new_resource.name}]"
        r.action :nothing
        r
      end

      def database_config_resource
        r = template ::File.join(app.shared_path, 'config', 'database.yml')
        r.source 'database.yml.erb'
        r.cookbook 'pushit'
        r.owner user_username
        r.group user_group
        r.mode '0644'
        r.variables(
          :database => app.database.to_hash,
          :environment => new_resource.environment
        )
        r.notifies :restart, "service[#{new_resource.name}]"
        r.action :nothing
        r
      end

      def filestore_config_resource
        r = template ::File.join(app.shared_path, 'config', 'filestore.yml')
        r.source 'filestore.yml.erb'
        r.cookbook 'pushit'
        r.owner user_username
        r.group user_group
        r.mode '0644'
        r.variables(
          :database => app.database.to_hash,
          :environment => new_resource.environment
        )
        r.notifies :restart, "service[#{new_resource.name}]"
        r.action :nothing
        r
      end

      def unicorn_config_resource
        r = template ::File.join(app.shared_path, 'config', 'unicorn.rb')
        r.source 'unicorn.rb.erb'
        r.cookbook 'pushit'
        r.user user_username
        r.group user_group
        r.mode '0644'
        r.variables(
          :enable_stats => new_resource.unicorn_enable_stats,
          :listen_port => new_resource.unicorn_listen_port,
          :listen_socket => app.upstream_socket,
          :upstart_pid => app.upstart_pid,
          :preload_app => new_resource.unicorn_preload_app,
          :stderr_path => ::File.join(app.shared_path, 'log', 'stderr.log'),
          :stdout_path => ::File.join(app.shared_path, 'log', 'stdout.log'),
          :worker_processes => worker_processes,
          :worker_timeout => new_resource.unicorn_worker_timeout,
          :working_directory => app.current_path
        )
        r.notifies :restart, "service[#{new_resource.name}]"
        r.action :nothing
        r
      end

      def worker_processes
        if config['env'] && config['env']['UNICORN_WORKER_PROCESSES'].to_i > 0
          worker_count = config['env']['UNICORN_WORKER_PROCESSES'].to_i
        else
          worker_count = new_resource.unicorn_worker_processes
        end

        unless worker_count && worker_count > 0
          fail StandardError, 'Unicorn worker count must be a positive integer'
        end

        worker_count
      end

      def bundle_install(release_path)
        install_command = "sudo su - #{user_username} -c 'cd #{release_path} && #{app.bundle_binary} install #{app.bundle_flags}'"

        begin
          require 'bundler'
          Bundler.clean_system(install_command)
        rescue => e
          Chef::Log.warn e.backtrace
        end
      end
    end
  end
end
