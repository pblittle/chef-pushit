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
        deploy.ssh_wrapper "#{app.user.ssh_directory}/#{config['deploy_key']}_deploy_wrapper.sh" do
          only_if do
            config['deploy_key'] && !config['deploy_key'].empty?
          end
        end

        deploy.environment config['env']
        deploy.user Etc.getpwnam(config['owner']).name
        deploy.group Etc.getgrnam(config['group']).name

        deploy.symlink_before_migrate({})
        deploy.create_dirs_before_symlink([])

        deploy.purge_before_symlink(
          %w{ log tmp/pids }
        )

        deploy.symlinks(
          { 'log' => 'log', 'pids' => 'pids' }
        )

        deploy.before_migrate do
          Chef::Log.debug("Installing NPM dependencies for #{new_resource.name}")

          execute "Install #{new_resource.name} with dependencies" do
            command "#{Pushit::Nodejs.npm_binary} install"
            cwd release_path
            user 'root'
            group 'root'
            environment new_resource.environment
          end
        end

        deploy.before_symlink nil
        deploy.before_restart nil
        deploy.after_restart nil

        deploy.run_action(new_resource.deploy_action)
      end

      def create_service_config
        r = Chef::Resource::Template.new(
          ::File.join('', 'etc', 'init', "#{new_resource.name}.conf"),
          run_context
        )
        r.source "#{new_resource.framework}.upstart.conf.erb"
        r.cookbook 'pushit'
        r.user 'root'
        r.group 'root'
        r.mode '0644'
        r.variables(
          :instance => new_resource.name,
          :env_path => Pushit::Nodejs.bin_path,
          :app_path => app.release_path,
          :log_path => ::File.join(
            app.shared_path, 'log', 'upstart.log'
          ),
          :pid_path => ::File.join(
            app.shared_path, 'pids', 'upstart.pid'
          ),
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
      end
    end
  end
end
