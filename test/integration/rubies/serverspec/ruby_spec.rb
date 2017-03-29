require 'spec_helper'

rubies_path = ::File.join('', 'opt', 'pushit', 'rubies')
ruby2_binary = ::File.join(rubies_path, '2.3.0', 'bin', 'ruby')
ruby2_bundler = ::File.join(rubies_path, '2.3.0', 'bin', 'bundle')
ree_binary = ::File.join(rubies_path, 'ree-1.8.7-2012.02', 'bin', 'ruby')

context 'general setup' do
  it 'created the rubies directory' do
    expect(file(rubies_path)).to be_directory
  end

  it 'has successfully installed ruby_build' do
    expect(command('su - deploy -c "which ruby-build"').exit_status).to eq(0)
  end

  it 'has successfully installed chruby' do
    expect(command('su - deploy -c "which chruby-exec"').exit_status).to eq(0)
  end

  it 'has sourced auto.sh in chruby.sh' do
    expect(file('/etc/profile.d/chruby.sh').content).to contain('auto.sh')
  end
end

context 'ruby ree with pushit default bundler' do
  it 'has successfully installed ree with env variables' do
    expect(command("#{ree_binary} -v").stdout).to contain('1.8.7')
  end
end

context 'ruby 2.0 with ruby default bundler' do
  it 'has successfully installed ruby 2.3' do
    expect(command("#{ruby2_binary} -v").stdout).to contain('2.3.0')
  end
  it 'has installed the right bulder version' do
    expect(command("#{ruby2_bundler} -v").stdout).to contain('1.14.6')
  end
end
