#
# Cookbook Name:: scpr-apps
# Recipe:: app_scprv4
#
# Copyright (c) 2014 Southern California Public Radio, All Rights Reserved.

package "libmysqlclient-dev"
package "libcurl4-openssl-dev"

scpr_apps "deploybot" do
  action      :run
  capistrano  true
  ruby        "2.1"
  app_type    :rails
  deploy_key  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7/3r2DdYZFicz47pCVik2IpPzGxkAiLToPbALeYpvFh6icV5Cwuim01wW1hSgzJJKIjgeY8V686qp2boM3tooi7ASUzEOUOFNlcMedsI4l6cuvQDrGl/xUaM5U174E1JtirFD4/3zx4zNNHV61wNq5gi41LCSrLmoVgZFi6EyagokZPiZIDxfVlLBY0TBLt+4+N907HHFBox66X3jRhBB8r9dj+AVA+wB+L5tmbrScvDupmCR6g0UBvNekG2dNpFtp3sqYhJ4zu6hRzHuPA3WYnxVRSRfVEVTUPAlXUjxyi7Xs0aV45f8kBr/z7wWrq5QQnNosf/3vJ3fAVUdajSh deploybot-deploy@scpr"

  setup ->(key,name,dir,config,env) {
    logrotate_app name do
      cookbook  "logrotate"
      path      ["#{dir}/shared/log/*.log"]
      size      100*1024*1024
      rotate    3
      options   ["missingok","compress","copytruncate"]
    end
  }

  roles({
    web: ->(key,name,dir,config) {
      include_recipe "scpr-apps::_nginx"

      # Call nginx setup
      # FIXME: Need to configure max workers here
      nginx_passenger_site name do
        action      :create
        dir         "#{dir}/current"
        server      "#{config.hostname} #{name}_web.service.consul"
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

      lifeguard_service "Deploybot Sidekiq (#{key})" do
        action        [:enable,:start]
        service       "deploybot-#{key}-sidekiq"
        user          name
        dir           dir
        monitor_dir   "#{dir}/current"
        command       "bundle exec sidekiq"
        path          "#{dir}/bin"
        env({
          "RAILS_ENV"   => key,
        })
      end

      # -- register service -- #

      consul_service_def "#{name}_worker" do
        action    :create
        tags      ["worker"]
        notifies  :reload, "service[consul]"
      end

      # Set up Lita
      scpr_apps_consul_elected_service "Deploybot Lita (#{key})" do
        action        [:enable,:start]
        service       "deploybot-#{key}-lita"
        key           "deploybot/#{key}/lita"
        user          name
        watch         "#{dir}/current/tmp/restart.txt"
        verbose       true
        command       "env RAILS_ENV=#{key} HOME=#{dir} PATH=#{dir}/bin:$PATH bundle exec lita start"
        cwd           "#{dir}/current/lita"
      end
    },
  })

end