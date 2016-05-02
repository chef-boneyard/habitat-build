#
# Cookbook Name:: habitat-build
# Recipe:: default
#

execute('apt-get update') { ignore_failure true }

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

# TODO: (jtimberman) Maybe we can discover this at some point, but it
# really doesn't matter - these are in the depot now, and will be
# available forevermore. Until they're not. And then we'll update
# this.
hab_pkgident = node['habitat-build']['hab-pkgident']
hab_bpm_pkgident = node['habitat-build']['hab-bpm-pkgident']
hab_studio_pkgident = node['habitat-build']['hab-studio-pkgident']

ENV['PATH'] = [
  "/hab/pkgs/#{hab_bpm_pkgident}/bin",
  "/hab/pkgs/#{hab_studio_pkgident}/bin",
  ENV['PATH']
].join(':')

remote_file '/tmp/core-hab-bpm.hart' do
  source "#{node['habitat-build']['depot-url']}/pkgs/#{hab_bpm_pkgident}/download"
end

package 'xz-utils'

# this needs to be extracted in / because reasons
execute 'extract-hab-bpm' do
  command 'tail -n +6 /tmp/core-hab-bpm.hart | xzcat | tar xf - -C /'
end

directory ::File.join(ENV['HOME'], 'plans/pandas') do
  recursive true
end

cookbook_file ::File.join(ENV['HOME'], 'plans/pandas/plan.sh') do
  source 'panda-plan.sh'
end

execute 'install-hab-studio' do
  command "/hab/pkgs/#{hab_bpm_pkgident}/bin/hab-bpm install core/hab-studio"
end

execute 'install-hab' do
  command "/hab/pkgs/#{hab_bpm_pkgident}/bin/hab-bpm install core/hab"
end

execute 'create-studio' do
  # TODO: (jtimberman) This needs to be a unique identifier for the workspace
  command 'hab-studio -r /hab/studios/build-cookbook new'
end
#
# maybe we generate the key on build? it's fast...
workspace = ENV['HOME'].gsub(%r{^/}, '').split('/').join('--')

directory "/hab/studios/#{workspace}/hab/cache/keys" do
  recursive true
end

keyname = nil
ruby_block 'keys' do
  block do
    command = "/hab/pkgs/#{hab_pkgident}/bin/hab"
    command << ' origin key generate'
    command << ' build-cookbook'
    key_gen = shell_out(command)
    keyname = key_gen.stdout.split.last
  end
end

# file 'pubkey' do
#   content lazy { IO.read("/hab/cache/keys/#{keyname}.pub")}
#   sensitive true
# end
#
# file 'privkey' do
#   content lazy { IO.read("/hab/cache/keys/#{keyname}.sig.key") }
#   sensitive true
# end

execute 'build-plan' do
  command 'hab-studio -r /hab/studios/build-cookbook build /src/plans/pandas'
end
