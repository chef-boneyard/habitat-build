# This recipe is a subset of the code available in publish
modified_habitat_plan_contexts.each do |plan_context|
  # Inside the build context, the "root" is called '/src'. In that scenario,
  # we want to use the project name as the package name
  pkg_name = plan_context == '/src' ? node['delivery']['change']['project'] : Pathname(plan_context).basename.to_s

  hab_build pkg_name do
    origin 'testorigin'
    plan_dir plan_context
    cwd '/plans'
    # ignore the failure because we won't have a valid auth token
    auth_token 'abcdef'
    ignore_failure true
    action :build
  end
end
