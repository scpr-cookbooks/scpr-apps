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

      lifeguard_service "StreamMachine Master (#{key})" do
        action        [:enable,:start]
        service       "streammachine-#{key}-master"
        command       "env ./node_modules/.bin/streammachine --config=./current/config/master.json"
        user          name
        dir           dir
        monitor_dir   "#{dir}/current"
        handoff       true
        restart       false
      end

      consul_service_def "#{name}_master" do
        action    [:create]
        tags      ["streammachine","master"]
        notifies  :reload, "service[consul]"
      end
    },
    slave: ->(key,name,dir,config) {
      lifeguard_service "StreamMachine Slave (#{key})" do
        action        [:enable,:start]
        service       "streammachine-#{key}-slave"
        command       "env ./node_modules/.bin/streammachine --config=./current/config/slave.json"
        user          name
        dir           dir
        monitor_dir   "#{dir}/current"
        handoff       true
        restart       false
      end

      consul_service_def "#{name}_slave" do
        action    [:create]
        tags      ["streammachine","slave"]
        notifies  :reload, "service[consul]"
      end
    }
  })
end