require_relative '../libraries/helpers'

resource_name :hab_build

actions :build, :publish
default_action :build

property :name, String, name_property: true
property :origin, String, required: true
property :plan_dir, String, required: true
property :cwd, String, required: true
property :url, String
property :artifact, String
property :home_dir, String
property :auth_token, String
property :live_stream, [TrueClass, FalseClass], default: true

action_class do
  include HabitatBuildCookbook::Helpers
end

action :build do
  execute 'build-plan' do
    command "sudo -E #{hab_binary} studio" \
            " -r #{hab_studio_path}" \
            " build #{plan_dir}"
    environment(
      'TERM' => 'vt100',
      'HAB_ORIGIN' => origin,
      'HAB_NONINTERACTIVE' => 'true'
    )
    cwd new_resource.cwd
    live_stream new_resource.live_stream
  end
end

action :publish do
  execute 'upload-pkg' do
    command lazy { "#{hab_binary} pkg upload --url #{url} #{hab_studio_path}/src/results/#{artifact}" }
    env(
      'HOME' => home_dir,
      'HAB_AUTH_TOKEN' => auth_token,
      'HAB_NONINTERACTIVE' => 'true'
    )
    live_stream new_resource.live_stream
    sensitive true
  end

  ruby_block "create Habitat project release: #{new_resource.name} #{build_version}" do
    block do
      # This helper is part of the Delivery Sugar DSL...it's also an alias
      # for `define_project_application`.
      create_workflow_application_release(
        new_resource.name,
        build_version,
        'artifact' => last_build_env.merge('type' => 'hart'),
        'delivery_data' => node['delivery']
      )
    end
  end
end
