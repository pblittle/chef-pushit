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

      def customize_deploy_revision_resource(r)
        r.migrate false
        r.migration_command nil

        r.before_migrate do
          app_provider.send(:before_migrate)
          app_provider.send(:npm_install_resource).action :run
        end

        r.before_restart do
          app_provider.send(:before_restart)
        end
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
