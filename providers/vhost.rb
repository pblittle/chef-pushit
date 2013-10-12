# encoding: utf-8
#
# Cookbook Name:: pushit
# Provider:: vhost
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

def load_current_resource
  @current_resource = Chef::Resource::PushitVhost.new(
    new_resource.name
  )

  run_context.include_recipe 'runit'

  @current_resource
end

def whyrun_supported?
  true
end

def app
  @app ||= Pushit::App.new(new_resource.name)
end

def config
  @config ||= app.config
end

action :create do

  bash "Create SSL Key for #{new_resource.name}" do
    cwd new_resource.install_path
    user 'root'
    group 'root'
    code <<-EOH
    umask 077
    openssl genrsa 2048 > #{new_resource.ssl_certificate_key}
    EOH

    not_if do
      ::File.exists?(new_resource.ssl_certificate_key)
    end
  end

  bash "Create SSL Certificate for #{new_resource.name}" do
    cwd new_resource.install_path
    user 'root'
    group 'root'
    code <<-EOH
    umask 077
    openssl req -x509 -nodes -days 3650 -subj '#{new_resource.ssl_request}' \
    -new -key #{new_resource.ssl_certificate_key} > \
    #{new_resource.ssl_certificate}
    cat #{new_resource.ssl_certificate_key} #{new_resource.ssl_certificate} > \
    #{new_resource.ssl_certificate_pem}
    EOH

    not_if do
      ::File.exists?(new_resource.ssl_certificate) &&
        ::File.exists?(new_resource.ssl_certificate_pem)
    end
  end

  site_config = ::File.join(
    new_resource.install_path, 'sites-available', "#{new_resource.app_name}.conf"
  )

  template "#{new_resource.app_name}.conf" do
    source "nginx_#{config['framework']}.conf.erb"
    path site_config
    cookbook new_resource.config_cookbook
    owner 'root'
    group 'root'
    mode '0644'
    variables(
      :app_name => new_resource.app_name,
      :root => app.root,
      :server_name => new_resource.server_name,
      :listen_port => new_resource.http_port,
      :use_ssl => new_resource.use_ssl,
      :ssl_certificate => new_resource.ssl_certificate,
      :ssl_certificate_key => new_resource.ssl_certificate_key,
      :ssl_listen_port => new_resource.https_port,
      :upstream_ip => new_resource.upstream_ip,
      :upstream_port => new_resource.upstream_port
    )

    notifies :reload, 'runit_service[nginx]' if ::File.symlink?(site_config)
  end

  nginx_site "#{new_resource.app_name}.conf"

  new_resource.updated_by_last_action(true)
end
