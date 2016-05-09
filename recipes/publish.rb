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

# Get the plan directory from the config, or fallback to /src, set
# this in .delivery/config.json.
#
# Examples:
# {
#   ...
#   "habitat": {
#     "plan_dir": "/src/plans"
#     "plan_dir": "/elsewhere/plans/myplan"
#   }
# }
plan_dir = if node['delivery']['config'].attribute?('habitat') &&
              node['delivery']['config']['habitat'].attribute?('plan_dir')
             node['delivery']['config']['habitat']['plan_dir']
           else
             '/src'
           end

artifact = nil
artifact_pkgident = nil
ruby_block 'build-plan' do
  block do
    Dir.chdir(node['delivery']['workspace']['repo'])
    ENV['TERM'] = 'ansi'
    command = "sudo #{::File.join('/hab/pkgs', hab_studio_pkgident, 'bin/hab-studio')}"
    command << " -r /hab/studios/#{studio_slug}"
    command << " build #{plan_dir}"
    build = shell_out(command)
    build_output = build.stdout.split("\n")
    artifact = build_output.grep(/Artifact:/).first.split[2]
    installed_path = build_output.grep(/Installed Path:/).first.split[3]
    artifact_pkgident = IO.read(::File.join(::File.join('/hab/studios', studio_slug), installed_path, 'IDENT')).chomp
  end
end

execute 'upload-artifact' do
  command lazy { "#{::File.join('/hab/pkgs', hab_pkgident, 'bin/hab')} artifact upload #{::File.join('/hab/studios/', studio_slug, artifact)}" }
end

ruby_block 'promote-artifact' do
  block do
    hc = Habitat::Client.new
    # TODO: (jtimberman) parameterize 'current' to the phase, or user input
    hc.promote_package(artifact_pkgident, 'current')
  end
end
