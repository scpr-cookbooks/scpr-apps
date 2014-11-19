include Chef::DSL::IncludeRecipe
use_inline_resources

action :install do
  # make sure the brightbox PPA is added
  include_recipe "apt"

  apt_repository "brightbox-ruby-ng" do
    uri           "http://ppa.launchpad.net/brightbox/ruby-ng/ubuntu"
    distribution  node["lsb"]["codename"]
    components    ["main"]
    keyserver     "hkp://keyserver.ubuntu.com:80"
    key           "C3173AA6"
  end

  packages = []

  packages << "ruby#{new_resource.version}"
  #packages << "rubygems"

  packages.each do |p|
    package p do
      action :install
    end
  end

  gem_package "bundler" do
    action      :install
    gem_binary  "/usr/bin/gem#{new_resource.version}"
    options     "--format-executable -n /usr/bin"
  end

end

action :link do
  if !new_resource.dir
    raise "Cannot link ruby without target directory."
  end

  directory new_resource.dir do
    action    :create
    recursive true
  end

  ["ruby","irb","gem","rake","bundle"].each do |bin|
    link "#{new_resource.dir}/#{bin}" do
      to      "/usr/bin/#{bin}#{new_resource.version}"
      action  :create
    end
  end
end