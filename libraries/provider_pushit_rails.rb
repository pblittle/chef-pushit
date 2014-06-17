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

      def initialize(new_resource, run_context = nil)
        @new_resource = new_resource
        @run_context = run_context

        @framework = 'rails'

        super(new_resource, run_context)
      end

      def load_current_resource; end

      private

      def create_deploy_revision
        require 'bundler'

        app_provider = self

        owner = config['owner']
        group = config['group']

        r = Chef::Resource::DeployRevision.new(
          new_resource.name,
          run_context
        )
        r.action new_resource.deploy_action
        r.deploy_to app.path

        r.repository config['repo']
        r.revision new_resource.revision
        r.shallow_clone true

        if config['deploy_key'] && !config['deploy_key'].empty?
          wrapper = "#{config['deploy_key']}_deploy_wrapper.sh"
          wrapper_path = ::File.join(app.user.ssh_directory, wrapper)

          r.ssh_wrapper wrapper_path
        end

        r.environment new_resource.environment

        r.user Etc.getpwnam(owner).name
        r.group Etc.getgrnam(group).name

        r.symlink_before_migrate({})

        bundle_binary = app.bundle_binary
        bundle_flags = app.bundle_flags

        before_migrate_symlinks = app.before_migrate_symlinks

        r.migrate new_resource.migrate
        r.migration_command '#{bundle_binary} exec rake db:migrate'

        r.before_migrate do
          app_provider.send(:create_dotenv)

          before_migrate_symlinks.each do |file, link|
            link "#{release_path}/#{link}" do
              to "#{new_resource.shared_path}/#{file}"
              owner owner
              group group
            end if ::File.exist? "#{new_resource.shared_path}/#{file}"
          end

          bundle_install_command = "sudo su - #{owner} -c 'cd #{release_path} && #{bundle_binary} install #{bundle_flags}'"

          begin
            Chef::Log.warn bundle_install_command + DateTime.now.to_s
            Bundler.clean_system(bundle_install_command)
          rescue => e
            Chef::Log.warn 'fail ' + bundle_install_command + DateTime.now.to_s
            Chef::Log.warn(e.backtrace)
          end

          app_provider.send(:before_migrate)
        end

        r.before_symlink do
          app_provider.send(:before_symlink)
        end

        precompile_assets = new_resource.precompile_assets
        precompile_command = new_resource.precompile_command

        r.before_restart do
          if precompile_assets

            bundle_precompile_command = "sudo su - #{owner} -c 'cd #{release_path} && source ./.env && #{bundle_binary} exec rake #{precompile_command}'"

            Chef::Log.warn bundle_precompile_command

            begin
              Bundler.clean_system(bundle_precompile_command)
            rescue => e
              Chef::Log.warn e.backtrace
            end
          end

          app_provider.send(:before_restart)
        end

        r.after_restart do
          app_provider.send(:after_restart)
        end

        r.run_action(new_resource.deploy_action)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_database_config
        r = Chef::Resource::Template.new(
          ::File.join(app.shared_path, 'config', 'database.yml'),
          run_context
        )
        r.source 'database.yml.erb'
        r.cookbook 'pushit'
        r.owner config['owner']
        r.group config['group']
        r.mode '0644'
        r.variables(
          :database => app.database.to_hash,
          :environment => new_resource.environment
        )
        r.run_action(:create)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_filestore_config
        r = Chef::Resource::Template.new(
          ::File.join(app.shared_path, 'config', 'filestore.yml'),
          run_context
        )
        r.source 'filestore.yml.erb'
        r.cookbook 'pushit'
        r.owner config['owner']
        r.group config['group']
        r.mode '0644'
        r.variables(
          :database => app.database.to_hash,
          :environment => new_resource.environment
        )
        r.run_action(:create)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
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

      def create_unicorn_config
        r = Chef::Resource::Template.new(
          ::File.join(app.shared_path, 'config', 'unicorn.rb'),
          run_context
        )
        r.source 'unicorn.rb.erb'
        r.cookbook 'pushit'
        r.user config['owner']
        r.group config['group']
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
        r.run_action(:create)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end
    end
  end
end
