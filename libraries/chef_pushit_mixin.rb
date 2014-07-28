# encoding: utf-8
#
# Cookbook Name:: pushit
# Library:: mixin
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

class Chef
  module Pushit
    module Mixin
      module App

        # if ree, "vendor/bundle/1.8"
        def bundle_path
          ::File.join('vendor', 'bundle')
        end

        def bundler_binstubs_path
          'bin'
        end

        def bundle_flags
          [
            '--deployment',
            '--without development:test',
            "--path #{bundle_path}",
            "--binstubs #{bundler_binstubs_path}",
            "--gemfile #{gemfile_path}",
            '-j4'
          ].join(' ')
        end

        def bundle_env_vars
          {
            'BUNDLE_GEMFILE' => '',
            'LANG' => 'en_US.UTF-8',
            'PATH' => "#{bin_paths}:$PATH",
            'RUBYOPT' => ''
          }
        end

        def nodejs_bin_path
          Pushit::Nodejs.bin_path if Pushit::Nodejs.installed?
        end

        def bundle_binary
          'bundle'
        end

        def embedded_bin_path
          ::File.join('', 'opt', 'chef', 'embedded', 'bin')
        end

        def gemfile_path
          'Gemfile'
        end

        def foreman_binary
          ::File.join(embedded_bin_path, 'foreman')
        end

        def unicorn_binary
          ::File.join(embedded_bin_path, 'unicorn')
        end
      end
    end
  end
end
