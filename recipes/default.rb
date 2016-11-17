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
apt_update cookbook_name

package ['xz-utils', 'shellcheck']

hab_install 'latest-habitat' do
  action :upgrade
end

# phases are run as the `dbuild` user, and we need to execute the
# `hab` command as root because it requires privileged access
# to bind mount the project directory in the studio.
file '/etc/sudoers.d/dbuild-hab' do
  content "dbuild ALL=(ALL) NOPASSWD: /bin/hab\n"
end

# Attempt to load the origin key from `delivery-secrets` data bag item
# named for this project. If it doesn't exist, we'll generate our own
# key. Some of these variables are not available until these resources
# are converged by chef, since generating the key will have a filename
# based on the timestamp when it was run.
keyname = nil
private_key = nil
public_key = nil

if habitat_origin_key?
  load_delivery_chef_config
  key_data = get_project_secrets
  private_key = key_data['habitat']['private_key']
  public_key = key_data['habitat']['public_key']
  keyname = key_data['habitat']['keyname']
else
  ruby_block 'origin-key-generate' do
    block do
      Dir.chdir(node['delivery']['workspace']['repo'])
      command = hab_binary
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
[
  '/hab/cache/keys',
  # Habitat 0.8.0+ looks for the key cache in $HOME if a `hab` command is
  # executed by a non-root user.
  File.join(delivery_workspace, '.hab', 'cache', 'keys')
].each do |key_cache_dir|
  directory key_cache_dir do
    recursive true
    owner 'root'
    group 'root'
  end

  file "#{key_cache_dir} private-key" do
    path lazy { File.join(key_cache_dir, "#{keyname}.sig.key") }
    content lazy { private_key }
    sensitive true
    owner 'dbuild'
    mode '0600'
  end

  file "#{key_cache_dir} public-key" do
    path lazy { File.join(key_cache_dir, "#{keyname}.pub") }
    content lazy { public_key }
    sensitive true
    owner 'dbuild'
    mode '0600'
  end
end
