#
# Cookbook Name:: habitat-build
# Recipe:: default
#
execute('apt-get update') { ignore_failure true }

package ['xz-utils', 'shellcheck']

# TODO: (jtimberman) Remove these and just use the habitat-client
# rubygem when we publish that to rubygems.org
chef_gem 'rbnacl' do
  version '3.3.0'
  compile_time true
end

chef_gem 'faraday' do
  version '0.9.2'
  compile_time true
end

hab_pkgident = node['habitat-build']['hab-pkgident']
hab_static_pkgident = node['habitat-build']['hab-static-pkgident']
hab_studio_pkgident = node['habitat-build']['hab-studio-pkgident']
file_cache_path = Chef::Config[:file_cache_path]

studio_slug = [
  node['delivery']['change']['project'],
  node['delivery']['change']['stage'],
  node['delivery']['change']['phase']
].join('-')

ENV['PATH'] = [
  "/hab/pkgs/#{hab_pkgident}/bin",
  "/hab/pkgs/#{hab_static_pkgident}/bin",
  "/hab/pkgs/#{hab_studio_pkgident}/bin",
  ENV['PATH']
].join(':')

remote_file "#{Chef::Config[:file_cache_path]}/core-hab-static.hart" do
  source "#{node['habitat-build']['depot-url']}/pkgs/#{hab_static_pkgident}/download"
end

execute 'extract-hab-static' do
  command "tail -n +6 #{file_cache_path}/core-hab-static.hart | xzcat | tar xf - -C /"
end

execute 'install-hab-studio' do
  command 'hab install core/hab-studio'
  cwd node['delivery']['workspace']['repo']
end

execute 'install-hab' do
  command 'hab install core/hab'
  cwd node['delivery']['workspace']['repo']
end

# phases are run as the `dbuild` user, and we need to execute the
# `hab-studio` command
file '/etc/sudoers.d/dbuild-hab-studio' do
  content "dbuild ALL=(ALL) NOPASSWD: /hab/pkgs/#{hab_studio_pkgident}/bin/hab-studio\n"
end

execute "remove-studio #{studio_slug}" do
  command "hab-studio -r /hab/studios/#{studio_slug} rm"
  cwd node['delivery']['workspace']['repo']
end

execute "create-studio #{studio_slug}" do
  command "hab-studio -r /hab/studios/#{studio_slug} new"
  cwd node['delivery']['workspace']['repo']
end

directory "/hab/studios/#{studio_slug}/hab/cache/keys" do
  recursive true
end

# Attempt to load the origin key from `delivery-secrets`
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
      keyname = key_gen.stdout.gsub(/\e\[(\d+)m/, '').chomp.split.last
      private_key = IO.read("/hab/cache/keys/#{keyname}sig.key")
      public_key = IO.read("/hab/cache/keys/#{keyname}pub")
    end
  end
end

file 'source-private-key' do
  path lazy { "/hab/cache/keys/#{keyname}sig.key" }
  content lazy { private_key }
  sensitive true
  owner 'dbuild'
  mode '0600'
end

file 'source-public-key' do
  path lazy { "/hab/cache/keys/#{keyname}pub" }
  content lazy { public_key }
  sensitive true
  owner 'dbuild'
  mode '0600'
end

file 'studio-private-key' do
  path lazy { "/hab/studios/#{studio_slug}/hab/cache/keys/#{keyname}sig.key" }
  content lazy { IO.read("/hab/cache/keys/#{keyname}sig.key") }
  sensitive true
  owner 'dbuild'
  mode '0600'
end

file 'origin-public-key' do
  path lazy { "/hab/studios/#{studio_slug}/hab/cache/keys/#{keyname}pub" }
  content lazy { IO.read("/hab/cache/keys/#{keyname}pub") }
  sensitive true
  owner 'dbuild'
  mode '0600'
end
