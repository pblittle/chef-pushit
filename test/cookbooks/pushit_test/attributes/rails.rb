default[:pushit_test]['rails-example'][:config][:owner] = 'deploy'
default[:pushit_test]['rails-example'][:config][:group] = 'deploy'
default[:pushit_test]['rails-example'][:config][:repo] = 'https://github.com/cloud66/sample-rails.4.0.0-mysql.git'
default[:pushit_test]['rails-example'][:config][:framework] = 'rails'
default[:pushit_test]['rails-example'][:config][:ruby][:version] = '2.1.1'
default[:pushit_test]['rails-example'][:config][:environment] = 'test'

default[:pushit_test]['rails-example'][:config][:webserver][:type] = 'nginx'
default[:pushit_test]['rails-example'][:config][:webserver][:server_name] = 'rails-example'

default[:pushit_test]['rails-example'][:config][:database][:host] = 'localhost'
default[:pushit_test]['rails-example'][:config][:database][:adapter] = 'mysql2'
default[:pushit_test]['rails-example'][:config][:database][:name] = 'rails-example'
default[:pushit_test]['rails-example'][:config][:database][:username] = 'root'
default[:pushit_test]['rails-example'][:config][:database][:password] = 'password'
default[:pushit_test]['rails-example'][:config][:database][:port] = 5432
default[:pushit_test]['rails-example'][:config][:database][:options] = Mash.new('foo' => 'bar')
default[:pushit_test]['rails-example'][:config][:database][:root_username] = 'root'
default[:pushit_test]['rails-example'][:config][:database][:root_password] = 'password'

default[:pushit_test]['rails-example'][:config][:env][:FOO] = 'bar'
default[:pushit_test]['rails-example'][:config][:env][:RACK_ENV] = 'test'
default[:pushit_test]['rails-example'][:config][:env][:RAILS_ENV] = 'test'
