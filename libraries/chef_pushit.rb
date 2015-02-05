# encoding: utf-8
#
# Cookbook Name:: pushit
# Library:: chef_pushit
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

require 'fileutils'

require_relative 'chef_pushit_mixin'

class Chef
  # all things pushit
  module Pushit
    PUSHIT_USER ||= 'deploy'.freeze
    PUSHIT_GROUP ||= 'deploy'.freeze
    PUSHIT_PATH ||= ::File.join('', 'opt', 'pushit').freeze

    PUSHIT_APP_DATA_BAG ||= 'pushit_apps'.freeze
    PUSHIT_APP_GEM_DEPENDENCIES ||= [
      { :name => 'bundler', :version => '1.7.2' },
      { :name => 'foreman', :version => '0.74.0' },
      { :name => 'unicorn', :version => '4.8.3' }
    ].freeze

    class << self
      def pushit_user
        @pushit_user ||= PUSHIT_USER
      end

      def pushit_group
        @pushit_group ||= PUSHIT_GROUP
      end

      def pushit_path
        @pushit_path ||= PUSHIT_PATH
      end

      def pushit_apps_path
        @pushit_apps_path ||= ::File.join(pushit_path, 'apps')
      end

      def pushit_app_config(name, lwrp_config = {})
        begin
          config = Chef::DataBagItem.load(PUSHIT_APP_DATA_BAG, name)
        rescue
          Chef::Log.warn("#{name} databag item does not exist")
          config = {}
        end

        Chef::Mixin::DeepMerge.deep_merge(lwrp_config.to_hash, config.to_hash)
      end

      # Depricated
      # TODO: remove it when we can
      def whyrun_supported
        @whyrun_supported ||= false
      end
      alias_method :whyrun_supported?, :whyrun_supported

      def escape_env(vars = {})
        vars.each_with_object({}) do |(key, value), hash|
          hash[key.upcase] = value.gsub(/"/) { '"' }
        end
      end
    end
  end
end
