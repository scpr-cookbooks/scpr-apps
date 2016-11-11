include_recipe "nginx_passenger"

template "/etc/nginx/conf.d/real_ip.conf" do
  action  :create
  source  "nginx.real_ip.conf.erb"
  owner   "www-data"
  mode    0644
  notifies :reload, "service[nginx]"
end

template "/etc/nginx/conf.d/banned_ips.conf.consul" do

end

# create an empty file first, so nginx doesn't complain that it's missing
file "/etc/nginx/conf.d/banned_ips.conf" do
  action    :create_if_missing
  content   "# Should be replaced via consul-template\n"
end

template "/etc/nginx/conf.d/banned_ips.conf.consul" do
  action    :create
  variables({
    consul_key: node.scpr_apps.banned_ip_key,
  })
  notifies  :reload, "service[consul-template]"
end

include_recipe "scpr-consul::consul-template"

consul_template_config "nginx-banned-ips" do
  action :create
  templates([
    {
      source:       "/etc/nginx/conf.d/banned_ips.conf.consul",
      destination:  "/etc/nginx/conf.d/banned_ips.conf",
      command:      "service nginx reload",
    }
  ])
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
