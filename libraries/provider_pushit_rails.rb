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

      def deploy_revision_resource
        app_provider = self

        username = user_username
        group = user_group
        ssh_directory = user_ssh_directory

        bundle_binary = app.bundle_binary

        r = deploy_revision new_resource.name
        r.deploy_to app.path

        r.repository config['repo']
        r.revision new_resource.revision
        r.shallow_clone true

        if config['deploy_key'] && !config['deploy_key'].empty?
          wrapper = "#{config['deploy_key']}_deploy_wrapper.sh"
          wrapper_path = ::File.join(ssh_directory, wrapper)

          r.ssh_wrapper wrapper_path
        end

        r.environment app.env_vars

        r.user username
        r.group group

        r.symlink_before_migrate(
          new_resource.symlink_before_migrate
        )

        r.migrate new_resource.migrate
        r.migration_command "#{bundle_binary} exec rake db:migrate"

        r.before_migrate do
          app_provider.send(:before_migrate)
          app_provider.send(:bundle_install)
        end

        r.before_symlink do
          app_provider.send(:before_symlink)
        end

        precompile_assets = new_resource.precompile_assets
        precompile_command = new_resource.precompile_command

        r.before_restart do
          if precompile_assets

            bundle_precompile_command = "sudo su - #{username} -c 'cd #{release_path} && source ./.env && #{bundle_binary} exec rake #{precompile_command}'"

            begin
              require 'bundler'
              Bundler.clean_system(bundle_precompile_command)
            rescue => e
              Chef::Log.warn e.backtrace
            end
          end

          app_provider.send(:before_restart)
        end

        command = app.restart_command
        r.restart_command do
          output = `#{command}`
          ::Chef::Log.debug "restart #{new_resource.name} returned\n #{output}"
        end

        r.after_restart do
          app_provider.send(:after_restart)
        end
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
          :stderr_path => ::File.join(app.current_path, 'log', 'stderr.log'),
          :stdout_path => ::File.join(app.current_path, 'log', 'stdout.log'),
          :worker_processes => worker_processes,
          :worker_timeout => new_resource.unicorn_worker_timeout,
          :working_directory => app.current_path
        )
        r.action :nothing
        r
      end

      def bundle_install
        install_command = "sudo su - #{user_username} -c 'cd #{app.release_path} && #{app.bundle_binary} install #{app.bundle_flags}'"

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
