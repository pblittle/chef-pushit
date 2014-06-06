# encoding: utf-8
#
# Cookbook Name:: pushit
# Library:: chef_pushit_nodejs
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
    class Nodejs
      class << self

        def prefix_path
          ::File.join('', 'usr', 'local')
        end

        def bin_path
          ::File.join(prefix_path, 'bin')
        end

        def node_binary
          ::File.join(bin_path, 'node')
        end

        def npm_binary
          ::File.join(bin_path, 'npm')
        end

        def installed?
          system("#{node_binary} -v") && $?.success?
        end
      end
    end
  end
end
