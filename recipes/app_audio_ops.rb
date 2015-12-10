#
# Cookbook Name:: scpr-apps
# Recipe:: app_audio_ops
#
# Copyright (c) 2014 Southern California Public Radio, All Rights Reserved.

package "libmysqlclient-dev"
package "libcurl4-openssl-dev"

scpr_apps "audio_ops" do
  action      :run
  capistrano  true
  ruby        "jruby-9.0.4.0"
  app_type    :rails
  deploy_key  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+LzOGe+C0IDwMTPuhgnCSnC6SEy+Lo8DqcUDjsOGBNZxBES202bDlEq5+UjdQB805g1qmldNKLM6NonTzIYX0cmnccvbPx2AuRe7uLBacmH/NnpHy786D9SvTki/xv0oGRuzSfGCu183OiXnuuZZ1PxU3HtLd2Sw2NoGqdurWlyqULFtzjvJKHVXqItk5k1QspCMK/+SRPZuV8idt47RlJrPkELC+NoVRdWkkoApA785FGqfr3sYnm1VrK71CJ4jKu+B7etvp4lJcwRpUAXHLh0qdWYRwHU7Qvjc06o1aoch+sjFPzjjWTsh4aF0nqC/jw9jGAOGLxAeQAnVzQSTJ audio_ops-deploy@scpr"

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

      nginx_passenger_site name do
        action        :create
        dir           "#{dir}/current"
        server        "#{config.hostname} #{name}_web.service.consul"
        rails_env     key
        log_format    "combined_timing"
        max_body_size "10M"
        ruby          "#{dir}/bin/jruby"
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
          app:  "audio_ops",
          env:  key,
        })
      end

    },
    worker: ->(key,name,dir,config) {
      # Set up resque pool
      include_recipe "lifeguard"

      lifeguard_service "Audio Ops Sidekiq (#{key})" do
        action        [:enable,:start]
        service       "audio_ops-#{key}-sidekiq"
        user          name
        dir           dir
        monitor_dir   "#{dir}/current"
        command       "bundle exec sidekiq"
        path          "#{dir}/bin"
        env({
          "RAILS_ENV"         => key,
        })
      end

      # -- register service -- #

      consul_service_def "#{name}_worker" do
        action    :create
        tags      ["worker"]
        notifies  :reload, "service[consul]"
      end

      # Set up scheduler
      scpr_apps_consul_elected_service "Audio Ops Scheduler (#{key})" do
        action        [:enable,:start]
        service       "audio_ops-#{key}-scheduler"
        key           "audio_ops/#{key}/scheduler"
        user          name
        watch         "#{dir}/current/tmp/restart.txt"
        verbose       true
        command       "env PATH=#{dir}/bin:$PATH RAILS_ENV=#{key} bundle exec rake scheduler"
        cwd           "#{dir}/current"
      end

    },
  })

end