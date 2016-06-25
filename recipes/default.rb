#
# Cookbook Name:: habitat-build
# Recipe:: default
#
# Copyright:: Copyright (c) 2016 Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# At this time we assume Ubuntu 15.04+ build nodes; these packages are
# not available on earlier Ubuntu releases.
execute('apt-get update') { ignore_failure true }

package ['xz-utils', 'shellcheck']

hab_pkgident = node['habitat-build']['hab-pkgident']
hab_studio_pkgident = node['habitat-build']['hab-studio-pkgident']
file_cache_path = Chef::Config[:file_cache_path]

# For example, if the project is `surprise-sandwich`, and we're in the
# Build stage's Publish phase, the slug will be:
#
#    `surprise-sandwich-build-publish`
studio_slug = [
  node['delivery']['change']['project'],
  node['delivery']['change']['stage'],
  node['delivery']['change']['phase']
].join('-')

ENV['PATH'] = [
  "/hab/pkgs/#{hab_pkgident}/bin",
  "/hab/pkgs/#{hab_studio_pkgident}/bin",
  ENV['PATH']
].join(':')

remote_file "#{Chef::Config[:file_cache_path]}/core-hab.hart" do
  source "#{node['habitat-build']['depot-url']}/pkgs/#{hab_pkgident}/download"
end

execute 'extract-hab' do
  command "tail -n +6 #{file_cache_path}/core-hab.hart | xzcat | tar xf - -C /"
end

# phases are run as the `dbuild` user, and we need to execute the
# `hab studio` command as root because it requires privileged access
# to bind mount the project directory in the studio.
file '/etc/sudoers.d/dbuild-hab-studio' do
  content "dbuild ALL=(ALL) NOPASSWD: /hab/pkgs/#{hab_studio_pkgident}/bin/hab-studio\n"
end

# Attempt to load the origin key from `delivery-secrets` data bag item
# named for this project. If it doesn't exist, we'll generate our own
# key. Some of these variables are not available until these resources
# are converged by chef, since generating the key will have a filename
# based on the timestamp when it was run.
keyname = nil
private_key = nil
public_key = nil

if habitat_secrets?
  load_delivery_chef_config
  key_data = get_project_secrets
  private_key = key_data['habitat']['private_key']
  public_key = key_data['habitat']['public_key']
  keyname = key_data['habitat']['keyname']
else
  ruby_block 'origin-key-generate' do
    block do
      Dir.chdir(node['delivery']['workspace']['repo'])
      command = "/hab/pkgs/#{hab_pkgident}/bin/hab"
      command << ' origin key generate'
      command << ' delivery'
      key_gen = shell_out(command)
      keyname = key_gen.stdout.gsub(/\e\[(\d+)m/, '').chomp.split.last.chop
      private_key = IO.read("/hab/cache/keys/#{keyname}.sig.key")
      public_key = IO.read("/hab/cache/keys/#{keyname}.pub")
    end
  end
end

# We need to have the keys permissions set correctly, and written out
# from either the generated data bag, or the key on disk itself. The
# latter is fine because Chef is convergent and won't change the file
# if it doesn't need to.
file 'source-private-key' do
  path lazy { "/hab/cache/keys/#{keyname}.sig.key" }
  content lazy { private_key }
  sensitive true
  owner 'dbuild'
  mode '0600'
end

file 'source-public-key' do
  path lazy { "/hab/cache/keys/#{keyname}.pub" }
  content lazy { public_key }
  sensitive true
  owner 'dbuild'
  mode '0600'
end
