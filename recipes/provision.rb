#
# Cookbook Name:: habitat-build
# Recipe:: provision
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

artifact_data = {}
ruby_block 'lookup-artifact-data' do
  block do
    load_delivery_chef_config
    artifact_data = search(project_slug, # ~FC003
                           "change_id:#{delivery_change_id}").first
    if artifact_data.empty? || !artifact_data['artifact_pkgident']
      raise 'Could not load artifact data!'
    end
  end
end

ruby_block 'promote-artifact' do
  block do
    hc = Habitat::Client.new
    hc.promote_package(artifact_data['artifact_pkgident'], node['delivery']['change']['stage'])
  end
end
