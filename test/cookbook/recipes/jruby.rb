# Test installing jruby using our LWRP

scpr_apps_ruby "jruby-9.0.4.0" do
  action [:install,:link]
  dir "/test/jruby-bin"
end