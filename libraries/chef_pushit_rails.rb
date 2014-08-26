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

#require_relative 'chef_pushit_app'

class Chef
  module Pushit
    # helper methods for rails app.  This app contains the "model" for rails apps
    class Rails < Chef::Pushit::App
      def restart_command
        command = <<-EOF
          if [ -e #{upstart_pid} ]
          then
            kill -USR2 `cat #{upstart_pid}`
          else
            start #{name}
          fi
        EOF
      end

      def procfile_default_entry
        'web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb'
      end
    end
  end
end