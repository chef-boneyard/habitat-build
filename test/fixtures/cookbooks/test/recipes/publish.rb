apt_update 'ubuntu'

package %w(curl sudo)

directory '/plans/pandas/habitat' do
  recursive true
end

cookbook_file '/plans/pandas/habitat/plan.sh' do
  source 'pandas-plan.sh'
end

hab_install 'hab'

execute 'hab origin key generate testorigin'

hab_build 'testbuild' do
  action [:build, :publish]
  cwd '/plans'
  environment('ABC' => 'XYZ')
  origin 'testorigin'
  plan_dir '/src/pandas'
  auth_token 'abcdef'
  # ignore the failure because we won't have a valid auth token
  ignore_failure true
end
