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

require File.expand_path('../resource_pushit_app', __FILE__)

class Chef
  class Resource
    class PushitHtml < Chef::Resource::PushitApp

      def initialize(name, run_context = nil)
        super

        @resource_name = :pushit_html
        @provider = Chef::Provider::PushitHtml
        @action = :create
        @allowed_actions = [:create]

        @framework = 'html'
      end
    end
  end
end
