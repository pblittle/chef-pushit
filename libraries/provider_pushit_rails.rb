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

        @framework = 'rails'
        @ruby = ruby

        @bundle_binary = @ruby.gem_path('bundle')
        @unicorn_binary = @ruby.gem_path('unicorn')

        super(new_resource, run_context)
      end

      def load_current_resource; end

      private

      def ruby
        @ruby || Pushit::Ruby.new(config['ruby'])
      end

      def create_deploy_revision

        Chef::Log.warn new_resource

        Chef::Log.debug("Creating deploy revision for #{new_resource.name}")

        deploy = Chef::Resource::DeployRevision.new(
          new_resource.name,
          run_context
        )
        deploy.action new_resource.deploy_action
        deploy.deploy_to app.path

        deploy.repository config['repo']
        deploy.revision new_resource.revision
        deploy.shallow_clone true
        deploy.ssh_wrapper "#{Pushit::User.home_path}/.ssh/#{config['deploy_key']}_deploy_wrapper.sh" do
          only_if do
            config['deploy_key'] && !config['deploy_key'].empty?
          end
        end

        deploy.environment new_resource.environment

        deploy.user Etc.getpwnam(config['owner']).name
        deploy.group Etc.getgrnam(config['group']).name

        deploy.symlink_before_migrate({})

        deploy.migrate true
        deploy.migration_command "#{@bundle_binary} exec rake db:migrate"

        app_config = config
        ruby_binary = @ruby.ruby_binary
        bundle_binary = @bundle_binary

        deploy.before_migrate do

          Chef::Log.debug("Symlinking files for #{new_resource.name}")

          link "#{release_path}/.env" do
            to "#{new_resource.shared_path}/env"
          end

          link "#{release_path}/.ruby-version" do
            to "#{new_resource.shared_path}/ruby-version"
          end

          link "#{release_path}/config/database.yml" do
            to "#{new_resource.shared_path}/config/database.yml"
          end

          link "#{release_path}/vendor/bundle" do
            to "#{new_resource.shared_path}/vendor_bundle"
          end

          Chef::Log.debug("Installing gems for #{new_resource.name}")

          bundle_flags = [
            '--binstubs',
            '--deployment',
            "--path #{new_resource.shared_path}/vendor_bundle",
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

        precompile_assets = new_resource.precompile_assets
        precompile_command = new_resource.precompile_command

        deploy.before_restart do

          Chef::Log.debug("Precompiling assets for #{new_resource.name}")

          precompile = Chef::Resource::Execute.new(
            'Precompile assets',
            run_context
          )
          precompile.command "#{release_path}/bin/rake #{precompile_command}"
          precompile.cwd release_path
          precompile.user app_config['owner']
          precompile.environment new_resource.environment
          precompile.run_action(:run)
          precompile.only_if { precompile_assets }
        end

        deploy.after_restart nil

        deploy.run_action(new_resource.deploy_action)
      end

      def create_dotruby
        Chef::Log.debug("Creating .ruby-version for #{new_resource.name}")

        dotruby = Chef::Resource::Template.new(
          ::File.join(app.shared_path, 'ruby-version'),
          run_context
        )
        dotruby.source 'ruby-version.erb'
        dotruby.cookbook 'pushit'
        dotruby.owner config['owner']
        dotruby.group config['group']
        dotruby.mode '0644'
        dotruby.variables(
          :ruby_version => config['ruby']
        )
        dotruby.run_action(:create)
      end

      def create_dotenv
        Chef::Log.debug("Creating .env for #{new_resource.name}")

        dotenv = Chef::Resource::Template.new(
          ::File.join(app.shared_path, 'env'),
          run_context
        )
        dotenv.source 'env.erb'
        dotenv.cookbook 'pushit'
        dotenv.owner config['owner']
        dotenv.group config['group']
        dotenv.mode '0644'
        dotenv.variables(
          :env => escape_env(config['env'])
        )
        dotenv.run_action(:create)
      end

      def create_database_yaml
        Chef::Log.debug("Creating database.yml for #{new_resource.name}")

        db_yaml = Chef::Resource::Template.new(
          ::File.join(app.shared_path, 'config', 'database.yml'),
          run_context
        )
        db_yaml.source 'database.yml.erb'
        db_yaml.cookbook 'pushit'
        db_yaml.owner config['owner']
        db_yaml.group config['group']
        db_yaml.mode '0644'
        db_yaml.variables(
          :database => {
            :adapter => config['database']['adapter'],
            :database => config['database']['name'],
            :encoding => config['database']['encoding'],
            :host => config['database']['host'],
            :username => config['database']['username'],
            :password => config['database']['password'],
            :options => config['database']['options'],
            :reconnect => config['database']['reconnect']
          },
          :environment => new_resource.environment
        )
        db_yaml.run_action(:create)
      end

      def create_service_config
        Chef::Log.debug("Creating service config for #{new_resource.name}")

        upstart_config = Chef::Resource::Template.new(
          ::File.join('', 'etc', 'init', "#{new_resource.name}.conf"),
          run_context
        )
        upstart_config.source "#{@framework}.upstart.conf.erb"
        upstart_config.cookbook 'pushit'
        upstart_config.user config['owner']
        upstart_config.group config['group']
        upstart_config.mode '0644'
        upstart_config.variables(
          :instance => new_resource.name,
          :env_path => ruby.bin_path,
          :app_path => app.release_path,
          :log_file => ::File.join(app.release_path, 'log', 'upstart.log'),
          :pid_file => ::File.join(app.release_path, 'tmp', 'pids', 'upstart.pid'),
          :config_file => ::File.join(app.release_path, 'config', 'unicorn.rb'),
          :exec => ::File.join(app.release_path, 'bin', 'unicorn'),
          :user => config['owner'],
          :group => config['group'],
          :env => escape_env(config['env']),
          :environment => escape_env(config['env'])['RACK_ENV']
        )
        upstart_config.run_action(:create)
        upstart_config.notifies(
          :restart,
          "service[#{new_resource.name}]",
          :delayed
        )
      end
    end
  end
end
