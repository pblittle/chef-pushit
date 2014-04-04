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

require File.expand_path('../provider_pushit_app', __FILE__)

class Chef
  class Provider

    # Convenience class for using the app resource with
    # the rails framework (provider)
    class PushitRails < Chef::Provider::PushitApp

      def initialize(new_resource, run_context = nil)
        @new_resource = new_resource
        @run_context = run_context
        @run_context.include_recipe('mysql::ruby')

        @framework = 'rails'

        super(new_resource, run_context)
      end

      def load_current_resource; end

      private

      def create_deploy_revision
        app_provider = self

        r = Chef::Resource::DeployRevision.new(
          new_resource.name,
          run_context
        )
        r.action 'force_deploy' # new_resource.deploy_action
        r.deploy_to app.path

        r.repository config['repo']
        r.revision new_resource.revision
        r.shallow_clone true

        r.ssh_wrapper "#{app.user.ssh_directory}/#{config['deploy_key']}_deploy_wrapper.sh" do
          only_if do
            config['deploy_key'] && !config['deploy_key'].empty?
          end
        end

        r.environment new_resource.environment

        r.user Etc.getpwnam(config['owner']).name
        r.group Etc.getgrnam(config['group']).name

        r.symlink_before_migrate({})

        r.migrate new_resource.migrate
        r.migration_command "#{ruby.bundle_binary} exec ./bin/rake db:migrate --trace"

        app_config = config

        ruby_binary = ruby.ruby_binary
        bundle_binary = ruby.bundle_binary

        r.before_migrate do
          link "#{release_path}/.env" do
            to "#{new_resource.shared_path}/env"
          end if ::File.exists? "#{new_resource.shared_path}/env"

          link "#{release_path}/.ruby-version" do
            to "#{new_resource.shared_path}/ruby-version"
          end if ::File.exists? "#{new_resource.shared_path}/ruby-version"

          link "#{release_path}/config/database.yml" do
            to "#{new_resource.shared_path}/config/database.yml"
          end if ::File.exists? "#{new_resource.shared_path}/config/database.yml"

          link "#{release_path}/config/filestore.yml" do
            to "#{new_resource.shared_path}/config/filestore.yml"
          end if ::File.exists? "#{new_resource.shared_path}/config/filestore.yml"

          link "#{release_path}/config/unicorn.rb" do
            to "#{new_resource.shared_path}/config/unicorn.rb"
          end if ::File.exists? "#{new_resource.shared_path}/config/unicorn.rb"

          bundle_flags = [
            '--binstubs',
            '--deployment',
            '--without test development',
            "--shebang=#{ruby_binary}"
          ].join(' ')

          bundle = Chef::Resource::Execute.new(
            'Install gems',
            run_context
          )
          bundle.command "#{bundle_binary} install #{bundle_flags}"
          bundle.cwd release_path
          bundle.user app_config['owner']
          bundle.environment new_resource.environment
          bundle.run_action(:run)
        end

        r.before_symlink do
          app_provider.send(:before_symlink)
        end

        precompile_assets = new_resource.precompile_assets
        precompile_command = new_resource.precompile_command

        r.before_restart do
          precompile = Chef::Resource::Execute.new(
            'Precompile assets',
            run_context
          )
          precompile.command "#{release_path}/bin/rake #{precompile_command}"
          precompile.cwd release_path
          precompile.user app_config['owner']
          precompile.environment new_resource.environment
          precompile.run_action(:run) if precompile_assets

          app_provider.send(:before_restart)
        end

        r.after_restart do
          app_provider.send(:after_restart)
        end

        r.run_action(new_resource.deploy_action)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def create_database_config
        environment = new_resource.environment

        if environment && config['database'].key?(environment)
          database = config['database'][environment]
        else
          database = config['database']
        end

        sslkey = database['options'] && database['options']['sslkey'] ? database['options']['sslkey'] : ''
        sslcert = database['options'] && database['options']['sslcert'] ? database['options']['sslcert'] : ''
        sslca = database['options'] && database['options']['sslca'] ? database['options']['sslca'] : ''

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
          :database => {
            :adapter => database['adapter'],
            :database => database['name'],
            :encoding => database['encoding'],
            :host => database['host'],
            :username => database['username'],
            :password => database['password'],
            :options => database['options'] || [],
            :reconnect => database['reconnect']
          },
          :environment => new_resource.environment
        )
        r.run_action(:create)

        fs_yaml = Chef::Resource::Template.new(
          ::File.join(app.shared_path, 'config', 'filestore.yml'),
          run_context
        )
        fs_yaml.source 'filestore.yml.erb'
        fs_yaml.cookbook 'pushit'
        fs_yaml.owner config['owner']
        fs_yaml.group config['group']
        fs_yaml.mode '0644'
        fs_yaml.variables(
          :database => {
            :adapter => database['adapter'],
            :database => database['name'],
            :host => database['host'],
            :username => database['username'],
            :password => database['password'],
            :sslkey => sslkey,
            :sslcert => sslcert,
            :sslca => sslca
          },
          :environment => new_resource.environment
        )
        fs_yaml.run_action(:create)
      end

      def worker_processes
        if config['env'] && config['env']['UNICORN_WORKER_PROCESSES'].to_i > 0
          worker_count = config['env']['UNICORN_WORKER_PROCESSES'].to_i
        else
          worker_count = new_resource.unicorn_worker_processes
        end

        unless worker_count && worker_count > 0
          raise StandardError, 'Unicorn worker count must be a positive integer'
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

      def export_upstart_config
        r = Chef::Resource::Template.new(
          app.service_config,
          run_context
        )
        r.source "#{@framework}.upstart.conf.erb"
        r.cookbook 'pushit'
        r.user config['owner']
        r.group config['group']
        r.mode '0644'
        r.variables(
          :instance => new_resource.name,
          :env_path => ruby.bin_path,
          :app_path => app.release_path,
          :log_path => app.log_path,
          :pid_file => app.upstart_pid,
          :config_file => ::File.join(
            app.shared_path, 'config', 'unicorn.rb'
          ),
          :exec => ::File.join(
            app.release_path, 'bin', 'unicorn'
          ),
          :user => config['owner'],
          :group => config['group'],
          :env => escape_env(config['env']),
          :environment => escape_env(config['env'])['RACK_ENV']
        )
        r.run_action(:create)
        r.notifies(
          :restart,
          "service[#{new_resource.name}]",
          :delayed
        )

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end
    end
  end
end
