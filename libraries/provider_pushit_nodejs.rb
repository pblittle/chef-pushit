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
    # the nodejs framework (provider)
    class PushitNodejs < Chef::Provider::PushitApp

      def initialize(new_resource, run_context = nil)
        @new_resource = new_resource
        @run_context = run_context

        @framework = 'nodejs'

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
        r.action new_resource.deploy_action
        r.deploy_to app.path

        r.repository config['repo']
        r.revision new_resource.revision
        r.shallow_clone true

        if config['deploy_key'] && !config['deploy_key'].empty?
          r.ssh_wrapper "#{app.user.ssh_directory}/#{config['deploy_key']}_deploy_wrapper.sh"
        end

        r.environment new_resource.environment

        r.user Etc.getpwnam(config['owner']).name
        r.group Etc.getgrnam(config['group']).name

        r.symlink_before_migrate({})
        r.create_dirs_before_symlink([])
        r.purge_before_symlink([])

        r.symlinks(
          'env' => '.env',
          'log' => 'log',
          'pids' => 'pids'
        )

        r.before_migrate do
          npm = Chef::Resource::Execute.new(
            "Install #{new_resource.name} dependencies",
            run_context
          )
          npm.command "#{Pushit::Nodejs.npm_binary} install"
          npm.cwd release_path
          npm.user 'root'
          npm.group 'root'
          npm.environment new_resource.environment
          npm.run_action :run
        end

        r.before_symlink do
          app_provider.send(:before_symlink)
        end

        r.before_restart nil

        r.after_restart do
          app_provider.send(:after_restart)
        end

        r.run_action(new_resource.deploy_action)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
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
          :env => escape_env(config['env'])
        )
        r.run_action(:create)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def service_create_upstart
        if app.procfile?
          foreman_export_upstart_config
        else
          export_upstart_config
        end
      end

      def foreman_export_upstart_config
        r = Chef::Resource::Execute.new(
          "Export #{new_resource.name} upstart config",
          run_context
        )
        r.command "sudo #{ruby.foreman_binary} export #{app.foreman_export_flags}"
        r.cwd app.release_path
        r.user 'root'
        r.group 'root'
        r.run_action :run

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
          :env_path => Pushit::Nodejs.bin_path,
          :app_path => app.release_path,
          :log_path => app.log_path,
          :pid_file => app.upstart_pid,
          :exec => new_resource.node_binary,
          :script_path => ::File.join(
            app.release_path, new_resource.script_file
          ),
          :user => config['owner'],
          :group => config['group'],
          :env => escape_env(config['env'])
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
