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

require 'chef/provider/lwrp_base'

require_relative 'provider_pushit_app'
require_relative 'chef_pushit_certs'

class Chef
  class Provider
    # provider class for creating a vhost config for pushit apps
    class PushitVhost < Chef::Provider::PushitBase
      use_inline_resources if defined?(use_inline_resources)

      def whyrun_supported?
        true
      end

      def action_create
        pushit_webserver 'nginx' do
          config_source new_resource.nginx_config_source
          config_cookbook new_resource.nginx_config_cookbook
          config_variables new_resource.nginx_config_variables
        end

        certificate.action :create if new_resource.ssl_certificate
        vhost_config_resource.action :create

        # need to re-declare this on the global resource collection so that the nginx_site definition
        # can notify it.  Eventually pushit_webserver needs a 'vhost' attribute for vhosts. so that
        # the resource can already exist from the nginx install.
        service('nginx') { action :nothing }

        nginx_site config_file do
          enable true
          notifies :reload, 'pushit_webserver[nginx]'
        end
      end

      def action_reload
        pushit_webserver 'nginx' do
          config_source new_resource.nginx_config_source
          config_cookbook new_resource.nginx_config_cookbook
          config_variables new_resource.nginx_config_variables
          action :reload
        end
      end

      private

      def config_file
        "#{new_resource.app_name}.conf"
      end

      def config_path
        ::File.join(
          new_resource.install_path, 'sites-available', config_file
        )
      end

      def certificate
        r = certificate_manage new_resource.ssl_certificate
        r.owner 'root'
        r.group 'root'
        r.cert_path Pushit::Certs.ssl_path('nginx')
        r.cert_file ::File.basename(Pushit::Certs.bundle_file(new_resource.ssl_certificate, 'nginx'))
        r.key_file ::File.basename(Pushit::Certs.key_file(new_resource.ssl_certificate, 'nginx'))
        r.nginx_cert true
        r.action :nothing
        r.notifies :reload, 'pushit_webserver[nginx]'
        r
      end

      # rubocop:disable Metrics/MethodLength,
      def vhost_config_resource
        if new_resource.use_ssl && !new_resource.ssl_certificate
          raise('use_ssl is true, but no ssl_certificate provided')
        end
        if new_resource.ssl_certificate
          cert = Pushit::Certs.bundle_file(new_resource.ssl_certificate, 'nginx')
          key = Pushit::Certs.key_file(new_resource.ssl_certificate, 'nginx')
        else
          cert = key = nil
        end

        r = template config_path
        r.source new_resource.config_source
        r.cookbook new_resource.config_cookbook
        r.owner 'root'
        r.group 'root'
        r.mode '0644'
        r.variables(
          { :app_name => new_resource.app_name,
            :root => new_resource.root,
            :server_name => new_resource.server_name,
            :listen_port => new_resource.http_port,
            :use_ssl => new_resource.use_ssl,
            :ssl_certificate => cert,
            :ssl_certificate_key => key,
            :ssl_listen_port => new_resource.https_port,
            :upstream_ip => new_resource.upstream_ip,
            :upstream_port => new_resource.upstream_port,
            :upstream_socket => new_resource.upstream_socket
          }.merge(new_resource.config_variables)
        )
        r.notifies :reload, 'pushit_webserver[nginx]'
        r
      end
    end
  end
end
