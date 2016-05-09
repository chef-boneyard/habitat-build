#
# Cookbook Name:: habitat-build
# Recipe:: lint
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

execute 'lint-check-plan' do
  # by targetting bash, we avoid warning on SC2148
  # https://github.com/koalaman/shellcheck/wiki/SC2148
  command "shellcheck -e #{node['habitat-build']['shellcheck-excludes'].join(',')} -s bash plan.sh"
  cwd node['delivery']['workspace']['repo']
end
