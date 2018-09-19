action :enable do
  service new_resource.service do
    provider  Chef::Provider::Service::Upstart
    action    :nothing
    supports  [:enable,:start,:restart,:stop]
  end

  # HACK to restart services on config changes
  service "#{new_resource.service}-stop" do
    service_name  new_resource.service
    provider      Chef::Provider::Service::Upstart
    action        :nothing
    supports      [:stop]
    notifies      :start, "service[#{new_resource.service}-start]", :immediately
  end

  service "#{new_resource.service}-start" do
    service_name  new_resource.service
    provider      Chef::Provider::Service::Upstart
    action        :nothing
    supports      [:start]
  end

  args = []

  if new_resource.server
    args << "--server #{new_resource.server}"
  end

  args << "--key #{new_resource.key}"
  args << %Q!--command "#{new_resource.command}"!

  if new_resource.cwd
    args << "--cwd #{new_resource.cwd}"
  end

  if new_resource.watch
    args << "--watch #{new_resource.watch}"
  end

  if new_resource.watch_restart
    args << "--restart"
  end

  if new_resource.verbose
    args << "--verbose"
  end

  # -- write upstart file -- #
  template "/etc/init/#{new_resource.service}.conf" do
    cookbook "scpr-apps"
    source "consul_elected-upstart.conf.erb"
    mode 0644
    variables({ :service => new_resource, :args => args })

    notifies :enable, "service[#{new_resource.service}]"

    if new_resource.restart
      notifies :stop, "service[#{new_resource.service}-stop]"
    end

  end
end

#----------

action :start do
  # -- start service -- #
  service new_resource.service do
    provider Chef::Provider::Service::Upstart
    action :start
  end
end

#----------

action :restart do
  # -- restart service -- #
  service new_resource.service do
    provider Chef::Provider::Service::Upstart
    action :restart
  end
end

#----------

action :stop do
  # -- stop service -- #
  service new_resource.service do
    provider Chef::Provider::Service::Upstart
    action :stop
  end
end

#----------

action :remove do
  file "/etc/init/#{new_resource.service}.conf" do
    action :delete
  end
end
