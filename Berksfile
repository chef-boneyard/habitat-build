source 'https://supermarket.chef.io'

metadata

cookbook 'delivery-truck'
cookbook 'delivery-sugar', git: 'https://github.com/chef-cookbooks/delivery-sugar.git'

group :test do
  cookbook 'test', path: './test/fixtures/cookbooks/test'
end
