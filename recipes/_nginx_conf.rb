template "/etc/nginx/nginx.conf" do
  source  "nginx.conf"
end

template "/etc/nginx/sites-available/assethost_dev.conf" do
  source  "assethost_dev.conf"
end

template "/etc/nginx/sites-available/assethost_prod.conf" do
  source  "assethost_prod.conf"
end

template "/etc/nginx/sites-available/default.conf" do
  source  "default.conf"
end

template "/etc/nginx/sites-available/dev01.conf" do
  source  "dev01.conf"
end

template "/etc/nginx/sites-available/firetracker_dev.conf" do
  source  "firetracker_dev.conf"
end

template "/etc/nginx/sites-available/firetracker_prod.conf" do
  source  "firetracker_prod.conf"
end

link '/etc/nginx/sites-enabled/assethost_dev.conf' do
  to '/etc/nginx/sites-available/assethost_dev.conf'
end

link '/etc/nginx/sites-enabled/assethost_prod.conf' do
  to '/etc/nginx/sites-available/assethost_prod.conf'
end

link '/etc/nginx/sites-enabled/default.conf' do
  to '/etc/nginx/sites-available/default.conf'
end

link '/etc/nginx/sites-enabled/dev01.conf' do
  to '/etc/nginx/sites-available/dev01.conf'
end

link '/etc/nginx/sites-enabled/firetracker_dev.conf' do
  to '/etc/nginx/sites-available/firetracker_dev.conf'
end

link '/etc/nginx/sites-enabled/firetracker_prod.conf' do
  to '/etc/nginx/sites-available/firetracker_prod.conf'
end

