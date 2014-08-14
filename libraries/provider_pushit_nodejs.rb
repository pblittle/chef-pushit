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
      private

      def deploy_revision_resource
        app_provider = self

        username = user_username
        group = user_group
        ssh_directory = user_ssh_directory

        r = deploy_revision new_resource.name
        r.action new_resource.deploy_action
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

        r.migrate false
        r.migration_command nil

        r.before_migrate do
          app_provider.send(:before_migrate)
          app_provider.send(:npm_install_resource).action :run
        end

        r.before_symlink do
          app_provider.send(:before_symlink)
        end

        r.before_restart do
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

        r.action :nothing

        r
      end

      def npm_install_resource
        r = execute "Install #{new_resource.name} dependencies"
        r.command "#{Pushit::Nodejs.npm_binary} install"
        r.cwd app.release_path
        r.user 'root'
        r.group 'root'
        r.action :nothing
        r
      end
    end
  end
end
