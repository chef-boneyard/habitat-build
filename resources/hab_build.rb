require_relative '../libraries/helpers'

resource_name :hab_build

property :origin, String, required: true
property :plan_dir, String, required: true
property :cwd, String, required: true
property :depot_url, String
property :channel, String
property :environment, Hash, default: {}
property :artifact, String
property :home_dir, String
property :auth_token, String
property :live_stream, [true, false], default: true

action_class do
  def artifact
    last_build_env['pkg_artifact']
  end

  def build_environment
    {
      'TERM' => 'vt100',
      'HAB_ORIGIN' => origin,
      'HAB_NONINTERACTIVE' => 'true',
    }.merge(new_resource.environment)
  end

  def build_environment_cli_string
    "env #{build_environment.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')}"
  end

  def build_version
    [last_build_env['pkg_version'], last_build_env['pkg_release']].join('/')
  end

  def package_name
    last_build_env['pkg_name']
  end

  def hab_studio_path
    ::File.join('/hab/studios', hab_studio_slug)
  end

  # For example, if the project is `surprise-sandwich`, and we're in the
  # Build stage's Publish phase, the slug will be:
  #
  #    `surprise-sandwich-build-publish`
  #
  def hab_studio_slug
    [
      node['delivery']['change']['project'],
      node['delivery']['change']['stage'],
      node['delivery']['change']['phase'],
    ].join('-')
  end

  # Read the last_build env file from the studio (if the path exists). Otherwise,
  # read it from the CWD.
  def results_dir
    if ::File.directory?(::File.join(hab_studio_path, 'src', 'results'))
      ::File.join(hab_studio_path, 'src', 'results')
    else
      ::File.join(new_resource.cwd, 'results')
    end
  end

  def last_build_env
    Hash[*::File.read(::File.join(results_dir, 'last_build.env')).split(/[=\n]/)]
  end
end

action :build do
  # Delete studio before we before we run. Run in Hab doesn't do this for us
  # but build does.
  execute 'remove-studio' do
    command "sudo -E #{hab_binary} studio -r #{hab_studio_path} rm"
    live_stream new_resource.live_stream
  end

  execute 'build-plan' do
    command "sudo -E #{hab_binary} studio" \
            " -r #{hab_studio_path}" \
            " run #{build_environment_cli_string} build #{plan_dir}"
    environment build_environment
    cwd new_resource.cwd
    retries new_resource.retries
    live_stream new_resource.live_stream
  end
end

action :publish do
  execute 'upload-pkg' do
    command(lazy do
      url_opt = []
      url_opt << "--channel #{channel}" if channel
      url_opt << "--url #{depot_url}" if depot_url
      "#{hab_binary} pkg upload #{url_opt.join(' ')} #{results_dir}/#{artifact}"
    end)
    env({
      'HOME' => home_dir,
      'HAB_AUTH_TOKEN' => auth_token,
      'HAB_NONINTERACTIVE' => 'true',
    }.merge(new_resource.environment))
    retries new_resource.retries
    live_stream new_resource.live_stream
  end
end

action :save_application_release do
  ruby_block 'create-automate-project-release' do
    block do
      Chef::Log.debug("Build version: #{build_version}")
      # This helper is part of the Delivery Sugar DSL...it's also an alias
      # for `define_project_application`.
      create_workflow_application_release(
        package_name,
        build_version,
        'artifact' => last_build_env.merge('type' => 'hart'),
        'delivery_data' => node['delivery']
      )
    end
  end
end
