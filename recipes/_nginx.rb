include_recipe "nginx_passenger"

template "/etc/nginx/conf.d/real_ip.conf" do
  action  :create
  source  "nginx.real_ip.conf.erb"
  owner   "www-data"
  mode    0644
  notifies :reload, "service[nginx]"
end

# -- Rotate all app logs -- #

logrotate_app "scpr-nginx-logs" do
  cookbook  "logrotate"
  path      ["#{node.nginx_passenger.log_dir}/*.access.log","#{node.nginx_passenger.log_dir}/*.error.log"]
  size      100*1024*1024
  rotate    3
  options   ["missingok","compress","copytruncate"]
end
