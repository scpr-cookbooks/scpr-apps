#
# Cookbook Name:: scpr-apps
# Recipe:: app_streammachine
#
# Copyright (c) 2014 Southern California Public Radio, All Rights Reserved.

scpr_apps "streammachine" do
  action      :run
  capistrano  true
  app_type    :nodejs
  deploy_key  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDog6p6jWE7eBvWmRc3c4ScNx7XhjGxLzlZpgda45zWQN2xjDAJ4lj+mcCQpd3NDkT3L8UzE9Tt9B1hn36u3/h6DU3UxswZ3hzquZG+l6soqsBC1m654NBF6i0lQCJ2W21US/m9rH7v+HXN5GIWO0daBskcwmz5daax+bdocJ81qCB+Xgdd0cK3yD6jGdcJu/MiNXb4lm5F6ZqRnjuqOqkszvdSXiMbpa7ltVRSJgrg8iQdPyCuacHWeo26Hmh5KWgJqNMDhYGYXHpldPUDm0jE9PiwhrAxfNy9D4oxJyae2SeLQAzxVS3J9VDNjOLbvZ+CetOyoM8+okLTFZqylUch streammachine-deploy@scpr"

  setup ->(key,name,dir,config,env) {
    include_recipe "lifeguard"
  }

  roles({
    master: ->(key,name,dir,config) {
      # we need ffmpeg on the master for transcoding
      include_recipe "scpr-tools::ffmpeg"

      # FIXME: This is totally attribute abuse. new_style is now old style
      if config[:new_style]
        command = "env ./streammachine-cmd --config=./config/master.json"

        lifeguard_service "StreamMachine Master (#{key})" do
          action        [:enable,:start]
          service       "streammachine-#{key}-master"
          command       command
          user          name
          dir           dir
          monitor_dir   "#{dir}/current"
          handoff       true
          restart       false
        end
      else
        include_recipe "runit"

        runit_service name do
          default_logger true
          run_template_name "streammachine"
          options({
            dir:    dir,
            user:   name,
            config: "#{dir}/current/config/master.json",
            watch:  "#{dir}/current/tmp/restart.txt",
          })
        end
      end

      consul_service_def "#{name}_master" do
        action    [:create]
        tags      ["streammachine","master"]
        notifies  :reload, "service[consul]"
      end
    },
    slave: ->(key,name,dir,config) {

      # FIXME: This is totally attribute abuse. new_style is now old style
      if config[:new_style]
        command = "env ./streammachine-cmd --config=./config/slave.json"

        lifeguard_service "StreamMachine Slave (#{key})" do
          action        [:enable,:start]
          service       "streammachine-#{key}-slave"
          command       command
          user          name
          dir           dir
          monitor_dir   "#{dir}/current"
          handoff       true
          restart       false
        end
      else
        include_recipe "runit"

        runit_service name do
          default_logger true
          run_template_name "streammachine"
          options({
            dir:    dir,
            user:   name,
            config: "#{dir}/current/config/slave.json",
            watch:  "#{dir}/current/tmp/restart.txt",
          })
        end
      end

      consul_service_def "#{name}_slave" do
        action    [:create]
        tags      ["streammachine","slave"]
        notifies  :reload, "service[consul]"
      end
    },
    standalone: ->(key,name,dir,config) {
      include_recipe "scpr-tools::ffmpeg"
      include_recipe "runit"

      runit_service name do
        default_logger true
        run_template_name "streammachine"
        options({
          dir:    dir,
          user:   name,
          config: "#{dir}/current/config/standalone.json",
          watch:  "#{dir}/current/tmp/restart.txt",
        })
      end

      consul_service_def "#{name}_standalone" do
        action    [:create]
        tags      ["streammachine","standalone"]
        notifies  :reload, "service[consul]"
      end
    },
  })
end