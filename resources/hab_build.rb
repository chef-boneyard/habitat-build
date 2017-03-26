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
  # The current acceptance environment on the server
  def existing_acceptance_environment
    Chef::ServerAPI.new.get("environments/#{get_acceptance_environment}")
  rescue Net::HTTPServerException => e
    raise e unless e.response.code.to_i == 404
    {}
  end

  def updated_environment_overrides
    existing_overrides = existing_acceptance_environment.fetch('override_attributes', {})
    existing_overrides['applications'] ||= {}
    existing_overrides['applications'][new_resource.name] = build_version
    existing_overrides
  end
end

action :build do
  execute 'build-plan' do
    command "sudo -E #{hab_binary} studio" \
            " -r #{hab_studio_path}" \
            " build #{plan_dir}"
    environment('TERM' => 'vt100',
                'HAB_ORIGIN' => origin,
                'HAB_NONINTERACTIVE' => 'true')
    cwd new_resource.cwd
    live_stream new_resource.live_stream
  end
end

action :publish do
  execute 'upload-pkg' do
    command lazy { "#{hab_binary} pkg upload --url #{url} #{hab_studio_path}/src/results/#{artifact}" }
    env('HOME' => home_dir,
        'HAB_AUTH_TOKEN' => auth_token,
        'HAB_NONINTERACTIVE' => 'true')
    live_stream new_resource.live_stream
    sensitive true
  end

  load_delivery_chef_config
  chef_data_bag new_resource.name

  # We need to be clear here to ensure that the magic done by cheffish
  # doesn't cause any unexpected data bag item naming or contents.
  # Thus, we have a unique project name for the resource, which does
  # not get used because we're setting the `id` and the `data_bag`
  # properties. We need to use `lazy {}` on the `id` and `raw_data`
  # because those contain calculated values from a previously
  # converged resource, `hab_build`, above.
  #
  chef_data_bag_item "store-#{new_resource.name}-artifact-data" do
    id lazy { build_version }
    data_bag new_resource.name
    raw_data lazy {
      { 'id' => build_version,
        'version' => build_version,
        'artifact' => last_build_env.merge('type' => 'hart'),
        'delivery_data' => node['delivery'] }
    }
  end

  chef_environment get_acceptance_environment do
    override_attributes lazy {
      updated_environment_overrides
    }
  end
end
