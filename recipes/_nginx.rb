include_recipe "nginx_passenger"

template "/etc/nginx/conf.d/real_ip.conf" do
  action  :create
  source  "nginx.real_ip.conf.erb"
  owner   "www-data"
  mode    0644
  notifies :reload, "service[nginx]"
end