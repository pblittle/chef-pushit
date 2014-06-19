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

        r.symlink_before_migrate(
          new_resource.before_migrate_symlinks
        )

        r.migrate false
        r.migration_command nil

        r.before_migrate do
          app_provider.send(:create_dotenv)

          app_provider.send(:npm_install)
          app_provider.send(:before_migrate)
        end

        r.before_symlink do
          app_provider.send(:before_symlink)
        end

        r.before_restart do
          app_provider.send(:before_restart)
        end

        r.after_restart do
          app_provider.send(:after_restart)
        end

        r.run_action(new_resource.deploy_action)

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end

      def npm_install
        r = Chef::Resource::Execute.new(
          "Install #{new_resource.name} dependencies",
          run_context
        )
        r.command "#{Pushit::Nodejs.npm_binary} install"
        r.cwd app.release_path
        r.user 'root'
        r.group 'root'
        r.run_action :run

        new_resource.updated_by_last_action(true) if r.updated_by_last_action?
      end
    end
  end
end
