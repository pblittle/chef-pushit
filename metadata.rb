# encoding: utf-8

name 'pushit'
maintainer 'P. Barrett Little'
maintainer_email 'barrett@barrettlittle.com'
license 'Apache 2.0'
description 'Installs/Configures Internet Applications'
long_description IO.read(
  File.join(
    File.dirname(__FILE__),
    'README.md'
  )
)

version '0.11'

supports 'debian'
supports 'ubuntu'

depends 'certificate', '= 0.5.2'
depends 'database', '~> 2.2'
depends 'git', '~> 4.0'
depends 'nginx', '~> 2.6'
depends 'nodejs', '~> 1.3'
depends 'ruby_build', '= 0.8.0'
depends 'runit', '= 1.5.10'
depends 'ssh', '= 0.6.6'
depends 'ssh_known_hosts', '~> 1.3'
depends 'sudo', '~> 2.6'

recommends 'apt', '~> 2.4'
recommends 'build-essential', '~> 2.0'
