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

if changed_habitat_files?
  project_secrets = get_project_secrets
  origin = 'delivery'

  if habitat_origin_key?
    keyname = project_secrets['habitat']['keyname']
    origin = keyname.split('-')[0...-1].join('-')
  end

  # set local variables we're going to use in `lazy` properties later in
  # the chef run
  build_version = nil
  project_name = node['delivery']['change']['project']

  # Only build and publish if we have a depot token
  if habitat_depot_token?
    habitat project_name do
      origin origin
      plan_dir habitat_plan_dir
      cwd node['delivery']['workspace']['repo']
      home_dir delivery_workspace
      auth_token project_secrets['habitat']['depot_token']
      url node['habitat-build']['depot-url']
      action [:build, :publish]
    end
  end

  #########################################################################
  # Save artifact data in data bag and environment (delivery-truck compat)
  #########################################################################

  # update a data bag with the artifact build info
  # TODO: (jtimberman) This is not the first time this has been used in
  # a delivery build cookbook. It's probably time to create a Chef
  # resource for this functionality
  ruby_block 'track-artifact-data' do # ~FC014
    block do
      load_delivery_chef_config
      proj = Chef::DataBag.new
      proj.name(project_name)
      proj.save

      proj_data = {
        'id' => build_version,
        'version' => build_version,
        'artifact' => last_build_env.merge('type' => 'hart'),
        'delivery_data' => node['delivery']
      }

      proj_item = Chef::DataBagItem.new
      proj_item.data_bag(proj.name)
      proj_item.raw_data = proj_data
      proj_item.save
    end
  end

  ruby_block 'set-build-version-in-environment' do
    block do
      load_delivery_chef_config
      begin
        to_env = Chef::Environment.load(get_acceptance_environment)
      rescue Net::HTTPServerException => http_e
        raise http_e unless http_e.response.code.to_i == 404
        to_env = Chef::Environment.new
        to_env.name(get_acceptance_environment)
        to_env.create
      end

      to_env.override_attributes['applications'] ||= {}
      to_env.override_attributes['applications'][project_name] = build_version
      to_env.save
    end
  end
end
