#
# Cookbook Name:: habitat-build
# Recipe:: publish
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

hab_pkgident = node['habitat-build']['hab-pkgident']
hab_studio_pkgident = node['habitat-build']['hab-studio-pkgident']

studio_slug = [
  node['delivery']['change']['project'],
  node['delivery']['change']['stage'],
  node['delivery']['change']['phase']
].join('-')

artifact = nil
artifact_hash = nil
artifact_pkgident = nil
ruby_block 'build-plan' do
  block do
    Dir.chdir(node['delivery']['workspace']['repo'])
    ENV['TERM'] = 'ansi'
    command = "sudo #{::File.join('/hab/pkgs', hab_studio_pkgident, 'bin/hab-studio')}"
    command << " -r /hab/studios/#{studio_slug}"
    command << " build #{habitat_plan_dir}"
    build = shell_out(command)
    build_output = build.stdout.split("\n")
    artifact = build_output.grep(/Artifact:/).first.split[2]
    installed_path = build_output.grep(/Installed Path:/).first.split[3]
    artifact_pkgident = IO.read(::File.join(::File.join('/hab/studios', studio_slug), installed_path, 'IDENT')).chomp
  end
end

ruby_block 'artifact-hash' do
  block do
    command = "/hab/pkgs/#{hab_pkgident}/bin/hab"
    command << " artifact hash #{::File.join('/hab/studios/', studio_slug, artifact)}"
    artifact_hash = shell_out(command).stdout.chomp
  end
end

execute 'upload-artifact' do
  command lazy { "#{::File.join('/hab/pkgs', hab_pkgident, 'bin/hab')} artifact upload #{::File.join('/hab/studios/', studio_slug, artifact)}" }
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
      'artifact_pkgident' => artifact_pkgident,
      'artifact_path' => artifact,
      'artifact_checksum' => artifact_hash,
      'artifact_type' => 'hart',
      'delivery_data' => node['delivery']
    }

    proj_item = Chef::DataBagItem.new
    proj_item.data_bag(proj.name)
    proj_item.raw_data = proj_data
    proj_item.save
  end
end
