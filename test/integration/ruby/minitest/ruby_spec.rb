# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::ruby' do

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

  it 'has created chruby.sh' do
    assert File.read(
      '/etc/profile.d/chruby.sh'
    ).include?('ree-1.8.7-2012.02')
  end

  it 'has added env vars to chruby.sh' do
    assert File.read(
      '/etc/profile.d/chruby.sh'
    ).include?('export RUBY_GC_MALLOC_LIMIT="50000000"')
  end

  let(:rubies_path) { ::File.join('', 'opt', 'pushit', 'rubies') }

  it 'has created a rubies directory' do
    assert File.directory?(rubies_path)
  end

  let(:mri_binary) do
    ::File.join(rubies_path, '1.9.3-p448', 'bin', 'ruby')
  end

  it 'has successfully installed mri' do
    assert system(
      "#{mri_binary} -v | grep -e '1.9.3p448'"
    )
  end

  let(:ree_binary) do
    ::File.join(rubies_path, 'ree-1.8.7-2012.02', 'bin', 'ruby')
  end

  it 'has successfully installed ree' do
    assert system(
      "#{ree_binary} -v | grep -e '1.8.7'"
    )
  end
end
