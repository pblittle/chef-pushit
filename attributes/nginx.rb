include_attribute 'pushit::default'
include_attribute 'nginx::default'
include_attribute 'nginx::source'

# from nginx::default
override['nginx']['version'] = '1.10.3'
override['nginx']['dir'] = '/opt/pushit/nginx'
override['nginx']['log_dir'] = '/opt/pushit/nginx/log'
override['nginx']['init_style'] = 'upstart'
override['nginx']['pid'] = '/opt/pushit/nginx/run/nginx.pid'
override['nginx']['gzip_static'] = 'on' # already the default
override['nginx']['default_site_enabled'] = false
override['nginx']['install_method'] = 'source'

override['nginx']['source']['version'] = node['nginx']['version']
override['nginx']['source']['checksum'] = '75020f1364cac459cb733c4e1caed2d00376e40ea05588fb8793076a4c69dd90'
override['nginx']['source']['prefix'] = "/opt/nginx-#{node['nginx']['source']['version']}"
override['nginx']['source']['conf_path'] = '/opt/pushit/nginx/nginx.conf'
override['nginx']['source']['sbin_path'] = "#{node['nginx']['source']['prefix']}/sbin/nginx"
override['nginx']['source']['default_configure_flags'] = %W(
  --prefix=#{node['nginx']['source']['prefix']}
  --conf-path=#{node['nginx']['source']['conf_path']}
  --sbin-path=#{node['nginx']['source']['sbin_path']}
)
override['nginx']['source']['url'] = "http://nginx.org/download/nginx-#{node['nginx']['source']['version']}.tar.gz"
default['nginx']['source']['modules'] |= [
  'nginx::http_gzip_static_module',
  'nginx::http_ssl_module',
  'nginx::http_stub_status_module'
]

override['nginx']['openssl_source']['version'] = '1.1.0e'
override['nginx']['openssl_source']['url'] = nil # force run_time construction.
