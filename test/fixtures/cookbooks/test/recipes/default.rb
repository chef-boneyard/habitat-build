# This is the default workspace used by delivery-sugar if there is no change
directory '/var/opt/delivery/workspace' do
  recursive true
end

group 'dbuild'

user 'dbuild' do
  group 'dbuild'
end

chef_ingredient 'chefdk'

execute 'verify' do
  command 'delivery job verify unit,lint,syntax --local'
  # environment('HOME' => '/var/opt/delivery/workspace')
  environment('PATH' => '$PATH:/opt/chefdk/bin')
  cwd '/var/opt/delivery/workspace'
  # user 'dbuild'

  # This doesn't actually work yes, because it wants a .git/config. Disbling and
  # we'll come back to it later.
  action :nothing
end
