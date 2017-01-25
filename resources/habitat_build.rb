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

action :build do
  execute 'build-plan' do
    command "sudo -E #{hab_binary} studio" \
            " -r #{hab_studio_path}" \
            " build #{plan_dir}"
    environment('TERM' => 'vt100', 'HAB_ORIGIN' => origin)
    cwd new_resource.cwd
    live_stream new_resource.live_stream
  end
end

action :publish do
  execute 'upload-pkg' do
    command lazy {
      "#{hab_binary} pkg upload" \
      " --url #{url}" \
      " #{hab_studio_path}/src/results/#{artifact}"
    }
    env(
      'HOME' => home_dir,
      'HAB_AUTH_TOKEN' => auth_token
    )
    live_stream new_resource.live_stream
    sensitive true
  end
end
