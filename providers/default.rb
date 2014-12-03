include Chef::DSL::IncludeRecipe

#use_inline_resources

def set_up_config(&block)
  (SCPRAppsStore.stashed[new_resource.name]||[]).each do |key,app_config|
    # turn scprv4 and prod into "scprv4_prod"
    name = [ new_resource.name, key ].join("_")

    # set up our directory path
    dir = [ new_resource.base_path, name ].join("/")

    # pull any settings values from Consul
    (SCPRAppsStore.pull_consul_settings("#{new_resource.name}/#{key}")||{}).each do |k,v|
      app_config[k] = v
    end

    yield key, name, dir, app_config
  end
end

action :run do
  set_up_config do |key,name,dir,app_config|
    puts "Running config for #{key} || #{name} || #{dir} || #{app_config}"

    env = Hashie::Mash.new(new_resource.env)

    # -- create user -- #

    user name do
      action  :create
      system  true
      shell   "/bin/bash"
      home    dir
    end

    # -- home directory -- #

    directory dir do
      action    :create
      owner     name
      mode      0755
      recursive true
    end

    directory "#{dir}/bin" do
      action  :create
      owner   name
      mode    0755
    end

    # -- Install a ruby? -- #

    if new_resource.ruby
      scpr_apps_ruby new_resource.ruby do
        action  [:install,:link]
        dir     "#{dir}/bin"
      end
    end

    # -- Capistrano Directories? -- #

    if new_resource.capistrano
      ['releases','shared','shared/system','shared/log','shared/pids'].each do |path|
        directory "#{dir}/#{path}" do
          action  :create
          owner   name
          mode    0755
        end
      end
    end

    # -- Deploy Credentials -- #

    directory "#{dir}/.ssh" do
      action  :create
      owner   name
      mode    0700
    end

    # Pre-seed a known_hosts file that knows github
    cookbook_file "#{dir}/.ssh/known_hosts" do
      action  :create_if_missing
      owner   name
      mode    0600
    end

    if new_resource.deploy_key
      # Write our deploy credentials
      file "#{dir}/.ssh/authorized_keys" do
        action  :create
        owner   name
        mode    0600
        content new_resource.deploy_key.is_a?(Array) ? new_resource.deploy_key.join("\n") : new_resource.deploy_key
      end
    end

    # -- Base Setup? -- #

    if new_resource.setup
      instance_exec(key,name,dir,app_config,env,&new_resource.setup)
    end

    # -- bash config -- #

    ["bash_profile","bashrc"].each do |f|
      template "#{dir}/.#{f}" do
        action  :create
        mode    0644
        owner   name
        source  "#{f}.erb"
        variables({
          key:key, name:name, dir:dir, app_config:app_config, resource:new_resource, bash_path:new_resource.bash_path, env:env
        })
      end
    end

    # -- Roles? -- #

    (app_config.roles||[]).each do |r|
      if new_resource.roles[ r.to_sym ]
        instance_exec(key,name,dir,app_config,&new_resource.roles[ r.to_sym ])
      else
        raise "Invalid role for SCPR app: #{new_resource.name}/#{r}"
      end
    end
  end
end
