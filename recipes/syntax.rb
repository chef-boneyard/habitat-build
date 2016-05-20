#
# Cookbook Name:: habitat-build
# Recipe:: syntax
#

execute 'syntax-check-plan' do
  command 'bash -n habitat/plan.sh'
  cwd node['delivery']['workspace']['repo']
end
