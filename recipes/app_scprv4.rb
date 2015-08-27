#
# Cookbook Name:: scpr-apps
# Recipe:: app_scprv4
#
# Copyright (c) 2014 Southern California Public Radio, All Rights Reserved.

package "libmysqlclient-dev"
package "libcurl4-openssl-dev"

scpr_apps "scprv4" do
  action      :run
  capistrano  true
  ruby        "2.1"
  app_type    :rails
  deploy_key  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHmN31EI2C6FmIj263YK5xHIp7PXw8SOp5Cp0QkxgXbn4kMIemC0TQ5oRbSuEqQAgDWYbBYSVxU24u6+PvuyjRbaP3+hpi89XrEMGbWJVZgdjaQuId0p+D/JLh7RPvNWgA5dMHJilGemAVl+4nw3jN/GVbx08zs9NxZGrJQGqdtdTF8Z4U0BFMzmY581UtqDMNa9LNNR9OREvhNaK4OO5g92Mw5R5CXZlVDLQMGWqL3mETGLT8OYo0echlWBH1rS2H2RdtXI05X8Y8zX7s30JVYWgFXm/zIEZzip7Yc6Kll8fBSK25/cx7gYAf1YOCh2xrySggVBDKxftIwmlpts1X scprv4_deploy@scpr"

  setup ->(key,name,dir,config,env) {
    if node.scpr_apps.nfs_enabled
      include_recipe "nfs"
      scpr_tools_media_mount "#{dir}/media" do
        action      :create
        remote_path node.scpr_apps.media_path
      end
    end

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
        action        :create
        dir           "#{dir}/current"
        server        "#{config.hostname} #{name}_web.service.consul"
        rails_env     key
        log_format    "combined_timing"
        max_body_size "75M"
      end

      # -- consul advertising -- #

      scpr_consul_web_service name do
        action    :create
        dir       "#{dir}/current"
        hostname  config.hostname
        path      "/"
        interval  '5s'
      end

      # -- logstash-forwarder -- #

      log_forward name do
        paths ["#{node.nginx_passenger.log_dir}/#{name}.access.log"]
        fields({
          type: "nginx",
          app:  "scprv4",
          env:  key,
        })
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
          "TERM_CHILD"        => 1,
          "RAILS_ENV"         => key,
          "RUN_AT_EXIT_HOOKS" => true,
        })
      end

      # -- register service -- #

      consul_service_def "#{name}_worker" do
        action    :create
        tags      ["worker"]
        notifies  :reload, "service[consul]"
      end

      # Set up scheduler
      scpr_apps_consul_elected_service "SCPRv4 Scheduler (#{key})" do
        action        [:enable,:start]
        service       "scprv4-#{key}-scheduler"
        key           "scprv4/#{key}/scheduler"
        user          name
        watch         "#{dir}/current/tmp/restart.txt"
        verbose       true
        command       "env PATH=#{dir}/bin:$PATH RAILS_ENV=#{key} bundle exec rake scheduler"
        cwd           "#{dir}/current"
      end

      # Set up Assethost pubsub cache expiration
      scpr_apps_consul_elected_service "SCPRv4 Asset Sync (#{key})" do
        action        [:enable,:start]
        service       "scprv4-#{key}-assetsync"
        key           "scprv4/#{key}/assetsync"
        user          name
        watch         "#{dir}/current/tmp/restart.txt"
        verbose       true
        command       "env PATH=#{dir}/bin:$PATH RAILS_ENV=#{key} bundle exec rake asset_sync"
        cwd           "#{dir}/current"
      end
    },
    contentbot: ->(key,name,dir,config) {
      # Set up Lita
      scpr_apps_consul_elected_service "SCPRv4 Contentbot (#{key})" do
        action        [:enable,:start]
        service       "scprv4-#{key}-contentbot"
        key           "scprv4/#{key}/contentbot"
        user          name
        watch         "#{dir}/current/tmp/restart.txt"
        verbose       true
        command       "env RAILS_ENV=#{key} HOME=#{dir} PATH=#{dir}/bin:$PATH bundle exec lita start"
        cwd           "#{dir}/current/lita"
      end

      # -- register service -- #

      consul_service_def "#{name}_contentbot" do
        action    :create
        tags      ["worker"]
        notifies  :reload, "service[consul]"
      end

    }
  })

end