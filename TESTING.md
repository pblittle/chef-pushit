Chef-Spec
-------------
Chef-spec tests can be run by simply calling `rspec`

Kitchen
-------------
Kitchen tests can be run by calling `kitchen test`, however you can also customize them in a few ways.

1. If you want to run with docker `KITCHEN_LOCAL_YAML='.kitchen.docker.yml' kitchen test`
2. If you want the test to run a bit quicker, you can set the KITCHEN_*_BOX env variables
  a. KITCHEN_BASE_BOX - basic ubuntu 12.04
  b. KITCHEN_NODE_BOX - ubuntu 12.04 with nodejs pre-installed
  c. KITCHEN_RUBY_BOX - ubuntu 12.04 with ruby already installed in /opt/pushit/rubies, as well as nodejs already installed

