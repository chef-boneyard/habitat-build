#
# Cookbook Name:: habitat-build
# Recipe:: publish
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

project_secrets = get_project_secrets
depot_token = project_secrets['habitat']['depot_token']
keyname = project_secrets['habitat']['keyname']

# set local variables we're going to use in `lazy` properties later in
# the chef run
artifact = nil
artifact_hash = nil
artifact_pkgident = nil
last_build_env = nil

execute 'build-plan' do
  command <<-EOH
sudo #{hab_studio_binary} \
-r #{hab_studio_path} \
-k #{keyname.split('-')[0...-1].join('-')} \
build #{habitat_plan_dir}
  EOH
  env(
    'TERM' => 'ansi'
  )
  cwd node['delivery']['workspace']['repo']
end

ruby_block 'load-build-output' do
  block do
    last_build_env = Hash[*::File.read(::File.join(hab_studio_path,
                                                   'src/results/last_build.env')).split(/[=\n]/)]

    artifact = last_build_env['pkg_artifact']
    artifact_pkgident = last_build_env['pkg_ident']
  end
end

ruby_block 'generate-pkg-hash' do
  block do
    command = hab_binary
    command << " pkg hash #{::File.join(hab_studio_path, '/src/results', artifact)}"
    artifact_hash = shell_out(command).stdout.chomp
  end
end

execute 'upload-pkg' do
  command lazy { "#{hab_binary} pkg upload --url #{node['habitat-build']['depot-url']} --auth '#{depot_token}' #{::File.join(hab_studio_path, '/src/results', artifact)}" }
end

# update a data bag with the artifact build info
# TODO: (jtimberman) This is not the first time this has been used in
# a delivery build cookbook. It's probably time to create a Chef
# resource for this functionality
ruby_block 'track-artifact-data' do # ~FC014
  block do
    load_delivery_chef_config
    proj = Chef::DataBag.new
    proj.name(project_slug)
    proj.save

    proj_data = {
      'id' => Time.now.utc.strftime('%F_%H%M'),
      'artifact' => last_build_env.merge('type' => 'hart', 'hash' => artifact_hash),
      'delivery_data' => node['delivery']
    }

    proj_item = Chef::DataBagItem.new
    proj_item.data_bag(proj.name)
    proj_item.raw_data = proj_data
    proj_item.save
  end
end
