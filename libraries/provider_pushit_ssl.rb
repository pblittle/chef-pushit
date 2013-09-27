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

require 'chef/provider'

class Chef
  class Provider
    class PushitSsl < Chef::Provider

      def initialize(new_resource, run_context = nil)
        @new_resource = new_resource
        @run_context = run_context

        @app = app

        super(new_resource, run_context)
      end

      def load_current_resource; end

      def whyrun_supported?
        Pushit.whyrun_enabled?
      end

      def action_install
        create_certs_directory
        create_certs
      end

      private

      def app
        @app || Pushit::App.new(new_resource.name)
      end

      def create_certs_directory
        dir = Chef::Resource::Directory.new(
          ::File.join(Pushit.pushit_path, 'certs'),
          run_context
        )
        dir.owner 'root'
        dir.group 'root'
        dir.recursive true
        dir.mode 00700
        dir.run_action(:create)

        if dir.updated_by_last_action?
          new_resource.updated_by_last_action(true)
        end
      end

      def create_certs
        app.config['ssl'].each do |key, value|
          file = Chef::Resource::CookbookFile.new(
            value,
            run_context
          )
          file.path ::File.join(Pushit.pushit_path, 'certs', value)
          file.mode 00600
          file.cookbook 'pushit'
          file.run_action(:create)

          if file.updated_by_last_action?
            new_resource.updated_by_last_action(true)
          end
        end
      end
    end
  end
end
