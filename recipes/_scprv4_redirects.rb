include_recipe "scpr-apps::_nginx"

cookbook_file "#{node.nginx_passenger.sites_dir}/scprv4_redirects" do
  action    :create
  source    "scprv4_redirects.nginx.conf"
  mode      0644
  notifies  :reload, "service[nginx]"
end