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

def habitat_plan_dir
  if node['delivery']['config'].attribute?('habitat') &&
     node['delivery']['config']['habitat'].attribute?('plan_dir')
    node['delivery']['config']['habitat']['plan_dir']
  else
    '/src/habitat'
  end
end

# if we're going to load secrets, we need to make sure we actually
# have the data!
def habitat_secrets?
  load_delivery_chef_config

  begin
    key_data = get_project_secrets.to_hash
  rescue Net::HTTPServerException
    return false
  end

  return false unless key_data.key?('habitat') && !key_data['habitat'].empty?
  %w(keyname private_key public_key).each do |req_key|
    if key_data['habitat'].key?(req_key) && !key_data['habitat'][req_key].empty?
      next
    else
      return false
    end
  end

  true
end
