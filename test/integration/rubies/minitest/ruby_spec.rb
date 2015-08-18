# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::ruby' do
  let(:rubies_path) { ::File.join('', 'opt', 'pushit', 'rubies') }

  let(:mri_binary) do
    ::File.join(rubies_path, '1.9.3-p448', 'bin', 'ruby')
  end

  let(:ree_binary) do
    ::File.join(rubies_path, 'ree-1.8.7-2012.02', 'bin', 'ruby')
  end

  it 'has created a rubies directory' do
    assert File.directory?(rubies_path)
  end

  it 'has successfully installed ruby_build' do
    assert system(
      'su - deploy -c "which ruby-build"'
    )
  end

  it 'has successfully installed chruby' do
    assert system(
      'su - deploy -c "which chruby-exec"'
    )
  end

  it 'chruby.sh sources auto.sh' do
    assert ::File.read(
      '/etc/profile.d/chruby.sh'
    ).include?('auto.sh')
  end

  it 'chruby.sh sources auto.sh' do
    assert ::File.read(
      '/etc/profile.d/chruby.sh'
    ).include?('auto.sh')
  end

  describe 'install ruby' do
    it 'has successfully installed mri' do
      assert system(
        "#{mri_binary} -v | grep -e '1.9.3p448'"
      )
    end
  end

  describe 'install ruby with env vars' do
    it 'has successfully installed ree' do
      assert system(
        "#{ree_binary} -v | grep -e '1.8.7'"
      )
    end
  end
end
