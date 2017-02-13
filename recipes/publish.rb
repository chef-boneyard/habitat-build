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
  load_delivery_chef_config
  chef_data_bag project_name

  chef_data_bag_item build_version do
    raw_data lazy do
      {
        'id' => build_version,
        'version' => build_version,
        'artifact' => last_build_env.merge('type' => 'hart'),
        'delivery_data' => node['delivery'],
      }
    end
  end

  chef_environment get_acceptance_environment do
    override_attributes lazy do
      { project_name => build_version }
    end
  end
end
