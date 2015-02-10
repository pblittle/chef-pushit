default[:pushit_test][:nodejs][:config][:owner] = 'deploy'
default[:pushit_test][:nodejs][:config][:group] = 'deploy'
default[:pushit_test][:nodejs][:config][:repo] = 'https://github.com/heroku/node-js-sample.git'
default[:pushit_test][:nodejs][:config][:framework] = 'nodejs'
default[:pushit_test][:nodejs][:config][:environment] = 'test'
default[:pushit_test][:nodejs][:config][:env] = Mash.new(:FOO => 'bar')
