source 'https://supermarket.chef.io'

metadata

# This is so we know where to get delivery-truck's dependency
cookbook 'delivery-sugar',
  git: 'https://github.com/chef-cookbooks/delivery-sugar.git',
  branch: 'master'

group :delivery do
  cookbook 'delivery_build', git: 'https://github.com/chef-cookbooks/delivery_build'
  cookbook 'delivery-base', git: 'https://github.com/chef-cookbooks/delivery-base'
  cookbook 'test', path: './test/fixtures/cookbooks/test'
end
