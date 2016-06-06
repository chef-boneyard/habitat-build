#
# Cookbook Name:: habitat-build
# Recipe:: provision
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

artifact_data = {}
ruby_block 'lookup-artifact-data' do
  block do
    load_delivery_chef_config
    artifact_data = search(project_slug, # ~FC003
                           "change_id:#{delivery_change_id}").first
    if artifact_data.empty? || !artifact_data['artifact']['pkg_ident']
      raise 'Could not load artifact data!'
    end
  end
end

ruby_block 'promote-artifact' do
  block do
    hc = Habitat::Client.new
    hc.promote_package(artifact_data['artifact']['pkg_ident'], node['delivery']['change']['stage'])
  end
end
