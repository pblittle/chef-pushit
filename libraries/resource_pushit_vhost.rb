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

require 'chef/resource/lwrp_base'

class Chef
  class Resource
    # resource class for pushit vhost configs
    class PushitVhost < Chef::Resource::LWRPBase
      self.resource_name = 'pushit_vhost'

      default_action :create
      actions :create, :reload

      attribute :app_name, :kind_of => String, :name_attribute => true

      attribute :config_cookbook, :kind_of => String, :default => 'pushit'
      attribute :config_source, :kind_of => String

      attribute :install_path, :kind_of => String, :default => '/opt/pushit/nginx'

      attribute :http_port, :kind_of => Integer, :default => 80
      attribute :https_port, :kind_of => Integer, :default => 443

      attribute :upstream_ip, :kind_of => String, :default => '0.0.0.0'
      attribute :upstream_port, :kind_of => Integer, :default => 3000
      attribute :upstream_socket, :kind_of => String

      attribute :server_name, :kind_of => String, :default => '_'

      attribute :use_ssl, :kind_of => [TrueClass, FalseClass], :default => false

      attribute :ssl_certificate, :kind_of => String
      attribute :ssl_certificate_key, :kind_of => String
      attribute :ssl_certificate_pem, :kind_of => String
    end
  end
end
