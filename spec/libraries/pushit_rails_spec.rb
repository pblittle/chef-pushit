require 'spec_helper'
require_relative '../../libraries/chef_pushit'

describe "#{Chef::Provider::PushitRails}.create" do
  let(:chef_run) do
    ChefSpec::Runner.new(
      :step_into => %w(pushit_rails pushit_app pushit_base),# deploy_revision),
      :log_level => :debug
    ).converge('pushit_test::rails')
  end

  before do
    allow(Chef::DataBagItem).to receive(:load).and_return(Hash.new)

    allow(Chef::DataBagItem).to(
      receive(:load).with('pushit_apps', 'rails-example').and_return(
        'id' =>  'rails-example',
        'owner' =>  'deploy',
        'group' =>  'deploy',
        'repo' =>  'https://github.com/cloud66/sample-rails.4.0.0-mysql.git',
        'framework' =>  'rails',
        'ruby' =>  {
          'version' =>  '2.1.1'
        },
        'environment' =>  'test',
        'webserver' =>  {
          'type' =>  'nginx',
          'server_name' =>  'rails-example',
          'certificate' => 'dummy'
        },
        'database' =>  {
          'host' =>  'localhost',
          'adapter' =>  'mysql2',
          'name' =>  'rails-example',
          'username' =>  'root',
          'password' =>  'password',
          'port' =>  5432,
          'options' =>  {
            'foo' =>  'bar',
            'sslca' =>   '/opt/pushit/certs/certs/cleardb-bundle.crt',
            # 'sslcert' => '/opt/pushit/certs/certs/cleardb.pem',
            'sslkey' =>  '/opt/pushit/certs/private/cleardb.key'
          },
          'root_username' =>  'root',
          'root_password' =>  'password',
          'certificate' => 'dummy'
        },
        'env' =>  {
          'FOO' =>  'bar',
          'RACK_ENV' =>  'test',
          'RAILS_ENV' =>  'test'
        }
      )
    )

    allow(Chef::DataBagItem).to(
      receive(:load).with('users', 'deploy').and_return(
        'id' =>  'deploy',
        'comment' =>  'Application Deployer',
        'ssh_private_key' =>  '-----BEGIN RSA PRIVATE KEY-----',
        'ssh_public_key' =>  'ssh-rsa',
        'ssh_deploy_keys' =>  [
          {
            'name' =>  'id_rsa_rails-example',
            'data' =>  '-----BEGIN RSA PRIVATE KEY-----\n=rails-example-deploy-key\n-----END RSA PRIVATE KEY-----'
           }
        ],
        'ssh_keys' =>  [
          'ssh-rsa == foo',
          'ssh-rsa == bar'
        ]
      )
    )

    my_deploy_double = double('deploy')
    deploy_resource = nil
    allow(Chef::Provider::Deploy::Revision).to receive(:new){ |resource, run_context|
      deploy_resource = resource
    }.and_return(my_deploy_double)
    allow(my_deploy_double).to receive(:action=)
    allow(my_deploy_double).to receive(:run_action) do
      puts "*****************\n\n*****************#{deploy_resource.action}*\n*\n*\n********************"
      recipe_eval(deploy_resource.before_migrate)
    end
    # {
#       deploy_resource.callback(:before_migrate, deploy_resource.new_resource.before_migrate)
#       deploy_resource.callback(:before_symlink, deploy_resource.new_resource.before_symlink)
#       deploy_resource.callback(:before_restart, deploy_resource.new_resource.before_restart)
#       deploy_resource.callback(:after_restart, deploy_resource.new_resource.after_restart)
#       puts "*****************\n\n*****************#{deploy_resource.new_resource.before_migrate}*\n*\n*\n********************"
#     }
  end

  include Chef::Pushit

  Chef::Pushit::PUSHIT_APP_GEM_DEPENDENCIES.each do |gem|
    it "installs the #{gem[:name]} gem" do
      expect(chef_run).to install_chef_gem(gem[:name])
    end

    it "restarts the app when #{gem[:name]} gem is installed or updated" do
      pending 'need to figure this out WRT monit'
      expect(chef_run.install_chef_gem(gem[:name])).to(
        notify('service[rails-example]').to(:restart).delayed
      )
    end
  end

  it 'creates the app directory' do
    expect(chef_run).to create_directory('/opt/pushit/apps/rails-example')
  end

  it 'creates the app shared directory' do
    expect(chef_run).to create_directory('/opt/pushit/apps/rails-example/shared')
  end

  # TODO: need to add logic to test we create the shared directories

  it 'creates the ruby-version file' do
    expect(chef_run).to create_template('/opt/pushit/apps/rails-example/shared/ruby-version')
  end

  # TODO: do we need to re-do the foreman stuff too??
  it 'restarts the app if the ruby version changes' do
    pending 'need to figure out how to do monit'
    expect(chef_run.template('/opt/pushit/apps/rails-example/shared/ruby-version')).to(
      notify('service[rails-example]').to(:restart).delayed
    )
  end

  it 'adds the database config' do
    expect(chef_run).to create_template('/opt/pushit/apps/rails-example/shared/config/database.yml')
  end

  it 'restarts the app if the database config changes' do
    pending 'need to figure out how to do monit'
    expect(chef_run.template('/opt/pushit/apps/rails-example/shared/config/database.yml')).to(
      notify('service[rails-example]').to(:restart).delayed
    )
  end

  it 'adds the filestore config' do
    expect(chef_run).to create_template('/opt/pushit/apps/rails-example/shared/config/filestore.yml')
  end

  it 'restarts the app if the filestore config changes' do
    pending 'need to figure out how to do monit'
    expect(chef_run.template('/opt/pushit/apps/rails-example/shared/config/filestore.yml')).to(
      notify('service[rails-example]').to(:restart).delayed
    )
  end

  it 'adds the unicorn config' do
    expect(chef_run).to create_template('/opt/pushit/apps/rails-example/shared/config/unicorn.rb')
  end

  it 'restarts the app if the unicron config changes' do
    pending 'need to figure out how to do monit'
    expect(chef_run.template('/opt/pushit/apps/rails-example/shared/config/unicorn.rb')).to(
      notify('service[rails-example]').to(:restart).delayed
    )
  end

  # TODO: what happens with a new cert?  nginx reload?
  it 'creates the webserver ssl cert' do
    pending
    expect(chef_run).to certificate_manage('/opt/pushit/apps/rails-example/shared/config/database.yml')
    expect(chef_run.certificate_manage('/opt/pushit/apps/rails-example/shared/config/database.yml')).to(
      notify('service[nginx]').to(:reload).delayed
    )
  end

  it 'creates the database ssl cert' do
    pending 'we need to figure out where database.certificate went'
    expect(chef_run).to certificate_manage('/opt/pushit/apps/rails-example/shared/config/database.yml')
    expect(chef_run.certificate_manage('/opt/pushit/apps/rails-example/shared/config/database.yml')).to(
      notify('service[nginx]').to(:reload).delayed
    )
  end

  it 'creates a vhost config for the app' do
    expect(chef_run).to create_pushit_vhost('rails-example')
  end

  it 'restarts the webserver if the vhost is updated' do
    pending
    expect(chef_run.create_pushit_vhost('rails-example')).to(notify('service[nginx]').to(:reload).delayed)
  end

  it 'creates the .env file' do
  #pending 'not stepping into deploy_revision'
    expect(chef_run).to create_template('/opt/pushit/apps/rails-example/shared/env')
  end

  # TODO: this will cause two deploys if shared/env is a new file
  it 're-runs the foreman job if the env file changes' do
    pending 'not stepping into deploy revision'
    expect(chef_run.template('/opt/pushit/apps/rails-example/shared/env')).to(
      notify('execute[run_foreman]').to(:run).delayed
    )
  end

  it 'creates the resources custom config files' do
    pending 'not stepping into the deploy_revision resource'
    expect(chef_run).to create_cookbook_file('/opt/pushit/app/rails-example/config/test_file.txt')
  end

  it 'restarts the app if any config files change' do
    pending 'need to figure out how to do monit'
    expect(chef_run.cookbook_file('/opt/pushit/app/rails-example/config/test_file.txt')).to(
      notify('service[rails-example]').to(:restart).delayed
    )
  end

  # Hm..... this could be interesting. How do we get it to run the deploy?
  it 'creates the procfile for rails-example app' do
    pending 'what is the proc file??'
    expect(chef_run).to create_file('/opt/pushit/apps/rails-example/releases/b41e9a3676edb38a28463c23112a25a23d850cf1/Procfile')
  end

  # TODO: creates the procfile and restarts when it changes
  # TODO: runs foreman
  # TODO: creates a service resource for the app

end
