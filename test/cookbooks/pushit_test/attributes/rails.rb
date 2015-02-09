default[:pushit_test]['rails-example'][:config][:owner] = 'deploy'
default[:pushit_test]['rails-example'][:config][:group] = 'deploy'
default[:pushit_test]['rails-example'][:config][:repo] = 'https://github.com/cloud66/sample-rails.4.0.0-mysql.git'
default[:pushit_test]['rails-example'][:config][:framework] = 'rails'
default[:pushit_test]['rails-example'][:config][:ruby][:version] = '2.1.1'
default[:pushit_test]['rails-example'][:config][:environment] = 'test'

default[:pushit_test]['rails-example'][:config][:webserver] = {
  :type => 'nginx',
  :server_name => 'rails-example'
}

default[:pushit_test]['rails-example'][:config][:database] = {
  :host => 'localhost',
  :adapter => 'mysql2',
  :name => 'rails-example',
  :username => 'root',
  :password => 'password',
  :port => 5432,
  :options => {'foo' => 'bar'},
  :root_username => 'root',
  :root_password => 'password'
}

default[:pushit_test]['rails-example'][:config][:env] = {
  :FOO => 'bar',
  :RACK_ENV => 'test',
  :RAILS_ENV => 'test'
}