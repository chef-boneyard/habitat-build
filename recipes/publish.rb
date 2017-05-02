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

  # Only build and publish if we have a depot token
  if habitat_depot_token? # ~FC023
    hab_build node['delivery']['change']['project'] do
      origin origin
      plan_dir habitat_plan_dir
      cwd node['delivery']['workspace']['repo']
      home_dir delivery_workspace
      auth_token project_secrets['habitat']['depot_token']
      depot_url node['habitat-build']['depot-url']
      action [:build, :publish, :save_application_release]
    end
  end
end
