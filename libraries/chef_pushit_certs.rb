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
    class Certs

      def self.ssl_path
        ::File.join(Pushit.pushit_path, 'ssl')
      end

      def self.certs_directory
        ::File.join(ssl_path, 'certs')
      end

      def self.keys_directory
        ::File.join(ssl_path, 'private')
      end
    end
  end
end