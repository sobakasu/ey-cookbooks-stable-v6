service "syslog-ng" do
  provider Chef::Provider::Service::Systemd
  action :nothing
end

package "syslog-ng" do
  action :install
  version node['syslog-ng']['version']
  notifies :restart, 'service[syslog-ng]'
end
