#
# Cookbook:: habitat-build
# Recipe:: publish
#
# Copyright:: 2016-2019, Chef Software Inc.
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
  if habitat_depot_token?
    modified_habitat_plan_contexts.each do |plan_context|
      # Inside the build context, the "root" is called '/src'. In that scenario,
      # we want to use the project name as the package name
      pkg_name = plan_context == '/src' ? node['delivery']['change']['project'] : Pathname(plan_context).basename.to_s

      hab_build pkg_name do
        origin origin
        plan_dir plan_context
        cwd workflow_workspace_repo
        home_dir workflow_workspace
        auth_token project_secrets['habitat']['depot_token']
        depot_url node['habitat-build']['depot-url']
        action [:build, :publish, :save_application_release]
      end
    end
  end
end
