#
# Cookbook Name:: scpr-apps
# Recipe:: app_scprv4
#
# Copyright (c) 2014 Southern California Public Radio, All Rights Reserved.

package "libmysqlclient-dev"

scpr_apps "scprv4" do
  action      :run
  capistrano  true
  ruby        "2.1"
  app_type    :rails
  deploy_key  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHmN31EI2C6FmIj263YK5xHIp7PXw8SOp5Cp0QkxgXbn4kMIemC0TQ5oRbSuEqQAgDWYbBYSVxU24u6+PvuyjRbaP3+hpi89XrEMGbWJVZgdjaQuId0p+D/JLh7RPvNWgA5dMHJilGemAVl+4nw3jN/GVbx08zs9NxZGrJQGqdtdTF8Z4U0BFMzmY581UtqDMNa9LNNR9OREvhNaK4OO5g92Mw5R5CXZlVDLQMGWqL3mETGLT8OYo0echlWBH1rS2H2RdtXI05X8Y8zX7s30JVYWgFXm/zIEZzip7Yc6Kll8fBSK25/cx7gYAf1YOCh2xrySggVBDKxftIwmlpts1X scprv4_deploy@scpr"

  roles({
    web: ->(key,name,dir,config) {
      include_recipe "nginx_passenger"

      # Call nginx setup
      # FIXME: Need to configure max workers here
      nginx_passenger_site "scprv4" do
        action      :create
        dir         "#{dir}/current"
        server      config.hostname
        rails_env   key
        log_format  "combined_timing"
      end

      # -- consul advertising -- #

      scpr_consul_web_service name do
        action    :create
        dir       "#{dir}/current"
        hostname  config.hostname
        path      "/"
        interval  '5s'
      end
    },
    worker: ->(key,name,dir,config) {
      # Set up resque pool
      include_recipe "lifeguard"

      lifeguard_service "SCPRv4 Resque (#{key})" do
        action        [:enable,:start]
        service       "scprv4-#{key}-resque"
        user          name
        dir           dir
        monitor_dir   "#{dir}/current"
        command       "bundle exec resque-pool"
        path          "#{dir}/bin"
        env({
          "TERM_CHILD"  => 1,
          "RAILS_ENV"   => name
        })
      end

      # -- register service -- #

      consul_service_def "#{name}_worker" do
        action    :create
        tags      ["worker"]
        notifies  :reload, "service[consul]"
      end

      # Set up scheduler


    },
  })

end