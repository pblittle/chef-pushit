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

require 'chef/resource'

class Chef
  class Resource
    class PushitSsl < Chef::Resource

      def initialize(name, run_context = nil)
        super

        @resource_name = :pushit_ssl
        @provider = Chef::Provider::PushitSsl
        @action = :install
        @allowed_actions.push :install
      end

      def name(arg = nil)
        set_or_return(
          :name,
          arg,
          :kind_of => [String],
          :required => true,
          :name_attribute => true
        )
      end

      def ca(arg = nil)
        set_or_return(
          :ca,
          arg,
          :kind_of => [String],
          :required => true
        )
      end

      def cert(arg = nil)
        set_or_return(
          :cert,
          arg,
          :kind_of => [String],
          :required => true
        )
      end

      def key(arg = nil)
        set_or_return(
          :key,
          arg,
          :kind_of => [String],
          :required => true
        )
      end
    end
  end
end