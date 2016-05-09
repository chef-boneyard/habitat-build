#
# Cookbook Name:: habitat-build
# Recipe:: syntax
#

execute 'syntax-check-plan' do
  command 'bash -n plan.sh'
  cwd node['delivery']['workspace']['repo']
end
