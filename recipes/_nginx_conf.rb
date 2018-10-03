template "/etc/nginx/nginx.conf" do
  source  "nginx.conf"
end

FILES=%w(assethost_dev.conf assethost_prod.conf default.conf dev01.conf firetracker_dev.conf firetracker_prod.conf)
FILES.each do |file|
  template "/etc/nginx/sites-available/#{file}" do
    source file
  end

  link "/etc/nginx/sites-enabled/#{file}" do
    to "/etc/nginx/sites-available/#{file}"
  end
end

