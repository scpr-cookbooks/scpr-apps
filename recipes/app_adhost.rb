#
# Cookbook Name:: scpr-apps
# Recipe:: app_assethost
#
# Copyright (c) 2014 Southern California Public Radio, All Rights Reserved.

package "libmysqlclient-dev"
package "libcurl4-openssl-dev"

scpr_apps "adhost" do
  action      :run
  capistrano  true
  ruby        "2.1"
  app_type    :rails
  deploy_key  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrz8eztepN13kgXxqPerr40YgQYJ2Efx9wwhTb7qWMz7NBbP5wbLG/XOzNsTkYGbnPdA2Ht9zfRRBkz1AJgYHTNBX9TvxOrUmarhGdR6JUdbO5GxitbdhnFUNQMyeJZMwFY+AQdEJGndWJ0oQpBwBoxM/D4qivUNA3biyppZ4q83cC3UFeb0hIVkenfNTegQ9/LqxtdPjcGxnYeVlpU4fBFc1cWN4NVvTfXKBHsbli1G9Xt0KyFMvOqihwFLCx4njuURrbq/WPXUeyTBVS86L3JJ+DCmH6T1l8Dhe0cFX/mCfWuH9LxPC0Muqi+bPUamx/qr3IqTv4pnZZMT6OBrjp adhost-deploy@scpr"

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
      nginx_passenger_site name do
        action        :create
        dir           "#{dir}/current"
        server        "#{config.hostname} #{name}_web.service.consul"
        rails_env     key
        log_format    "combined_timing"
        max_body_size "20M"
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
      # install ffmpeg
      include_recipe "scpr-tools::ffmpeg"

      # Set up resque pool
      include_recipe "lifeguard"

      lifeguard_service "Adhost Resque (#{key})" do
        action        [:enable,:start]
        service       "adhost-#{key}-resque"
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

      # -- Set up Scheduler -- #

      # 7/10/2015: change to :stop,:remove. Service can be removed next
      scpr_apps_consul_elected_service "AdHost Scheduler (#{key})" do
        action        [:stop,:remove]
        service       "adhost-#{key}-scheduler"
        key           "adhost/#{key}/scheduler"
        user          name
        watch         "#{dir}/current/tmp/restart.txt"
        verbose       true
        command       "env PATH=#{dir}/bin:$PATH RAILS_ENV=#{key} bundle exec rake scheduler"
        cwd           "#{dir}/current"
      end
    },
  })

end