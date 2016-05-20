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
