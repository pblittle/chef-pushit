def install_ruby_build_ruby(resource_name)
  ChefSpec::Matchers::ResourceMatcher.new(:ruby_build_ruby, :install, resource_name)
end


ChefSpec::Runner.define_runner_method :deploy_revision
def deploy_deploy_revision(resource_name)
  ChefSpec::Matchers::ResourceMatcher.new(:deploy_revision, :deploy, resource_name)
end