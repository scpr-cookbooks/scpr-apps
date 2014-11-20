#
# Cookbook Name:: scpr-apps
# Recipe:: default
#
# Copyright (c) 2014 Southern California Public Radio, All Rights Reserved.

# -- Make sure consul agent is installed -- #

include_recipe "scpr-consul"

# -- Look for app configuration -- #

# FIXME: The use of a databag is just a placeholder for now. Eventually this
# will be via an out-of-band service

config = {}
if node.scpr_apps.config
  config = node.scpr_apps.config
elsif (c = begin data_bag_item(node.scpr_apps.databag, node.name) rescue nil end)
  config = c
end

SCPRAppsStore.stash( Hashie::Mash.new(config) )

# -- load previous config -- #

old_config = SCPRAppsStore.load_for(node)

# -- Process current config -- #

config.each do |key,app|
  # run the recipe for our app
  include_recipe "scpr-apps::app_#{key}"
end

# -- Anything to deprovision? -- #



# -- Save our new config -- #

SCPRAppsStore.save_for(node,config)
