# encoding: utf-8
#
# Cookbook Name:: pushit
# Library:: chef_pushit_certs
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

require_relative 'chef_pushit'

class Chef
  module Pushit
    # Model class for pushit certificate
    class Certs
      def self.ssl_path(relative_to = nil)
        return ::File.join(Pushit.pushit_path, 'ssl') unless relative_to
        ::File.join(Pushit.pushit_path, relative_to, 'ssl')
      end

      def self.certs_path(relative_to = nil)
        ::File.join(ssl_path(relative_to), 'certs')
      end

      def self.keys_path(relative_to = nil)
        ::File.join(ssl_path(relative_to), 'private')
      end

      def self.key_extension
        '.key'
      end

      def self.cert_extension
        '.crt'
      end

      def self.bundle_extension
        '-bundle.crt'
      end

      def self.chain_extension
        '.chain'
      end

      def self.cert_file(cert_name, relative_to = nil)
        ::File.join(certs_path(relative_to), cert_name + cert_extension)
      end

      def self.key_file(cert_name, relative_to = nil)
        ::File.join(keys_path(relative_to), cert_name + key_extension)
      end

      def self.chain_file(cert_name, relative_to = nil)
        ::File.join(certs_path(relative_to), cert_name + chain_extension)
      end

      def self.bundle_file(cert_name, relative_to = nil)
        ::File.join(certs_path(relative_to), cert_name + bundle_extension)
      end
    end
  end
end
