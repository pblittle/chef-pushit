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

    # Convenience class for using the app resource to create
    # a vanilla HTML website (provider)
    class PushitHtml < Chef::Provider::PushitApp

      def initialize(new_resource, run_context = nil)
        @new_resource = new_resource
        @run_context = run_context

        @framework = 'html'

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
        deploy.ssh_wrapper "#{app.user.home}/.ssh/#{config['deploy_key']}_deploy_wrapper.sh" do
          only_if do
            config['deploy_key'] && !config['deploy_key'].empty?
          end
        end

        deploy.user Etc.getpwnam(config['owner']).name
        deploy.group Etc.getgrnam(config['group']).name

        deploy.symlinks({})
        deploy.purge_before_symlink([])
        deploy.create_dirs_before_symlink([])
        deploy.symlink_before_migrate({})

        deploy.before_migrate nil
        deploy.before_restart nil
        deploy.after_restart nil

        deploy.run_action(new_resource.deploy_action)
      end

      def create_service_config; end

      def enable_and_start_service; end
    end
  end
end
