#
# Copyright:: Copyright (c) 2016 Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# plan_dir vs plan_context
#   plan_dir: The directory where the plan.sh file is located.
#   plan_context: The directory where either the 'habitat' folder or plan.sh file is located.
#
# The reason we make this distinction in this helper is primarily for the purpose
# of detecting modified "services". Let's say you have a structure like this:
#
# . (root directory)
# ├── bin
# |   ├── (files ...)
# ├── habitat
# |   ├── plan.sh
# ├── lib
# |   ├── (files...)
#
# For a user of this cookbook, they'll likely want to trigger a build if a file
# in `bin` or `lib` changes. In order to facilitate that, we need to consider the
# larger "plan_context" (all the files in the root directory) and not just the
# "plan_dir" (just the habitat folder with the plan.sh). This cookbook
# differentiates these two concepts by using the terms plan_dir vs plan_context.
#
# From a Habitat perspective, the build command can take either the plan_dir or
# the plan_context, so which one we use is of lttle consequence.
#
module HabitatBuildCookbook
  module Helpers
    #
    # Inspects your .delivery/config.json for the habitat['plan_dir'] value. This
    # value can either be a string or an array of strings. Each string should be
    # the directory where your plan.sh file is located.
    #
    # Example #1: If your plan.sh is located in /src/plan-a/habitat/plan.sh
    # {
    #   ...
    #   "habitat": {
    #     "plan_dir": "/src/plan-a/habitat"
    #   }
    # }
    #
    # Example #2: Single plan directory elsewhere in in your studio, specified as an array
    # {
    #   ...
    #   "habitat": {
    #      "plan_dir": [
    #        "/elsewhere/plans/myplan"
    #      ]
    #   }
    # }
    #
    # Example #3: List of plans that will be built (in order)
    # This is very useful if you only want to build a subset of plans, or build
    # them in a specific order.
    # {
    #   ...
    #   "habitat": [
    #     "/src/myplans/plan-a/habitat",
    #     "/src/myplans/plan-b/habitat",
    #     "/elsewhere/plans/myplan"
    #   ]
    # }
    def habitat_plan_dir
      if habitat_plan_dir_specified?
        [node['delivery']['config']['habitat']['plan_dir']].flatten
      else
        '/src/habitat'
      end
    end

    #
    # Returns all the Habitat **plan_contexts** in the current repository as an array.
    #
    # If one or more plan contexts were specified via the plan_dir value in the
    # .delivery/config.json, use that list and return the associated plan_contexts.
    # Otherwise, search the repository for Habitat plan contexts.
    #
    # Example 1: habitat_plan_dir
    #
    # habitat_plan_dir
    # => ["/src/myplans/plan-a/habitat", "/src/myplans/plan-b/habitat", "/elsewhere/plans/myplan"]
    # habitat_plan_contexts
    # => ["/src/myplans/plan-a", "/src/myplans/plan-b", "/elsewhere/plans/myplan"]
    #
    #
    def habitat_plan_contexts
      # Assume that someone specifying the plan directories knows that they want
      # and defer to that list. Otherwise, search the repository for potential
      # Habitat plan directories.
      plan_contexts = habitat_plan_dir_specified? ? habitat_plan_dir : detect_plan_dirs

      # If the user did not specify any plan directories,
      # Search the repository for any habitat PLAN_CONTEXTs
      all_dirs = plan_contexts.map do |plan_file|
        plan_context_path = Pathname(plan_file).each_filename.to_a
        plan_context_path.pop if plan_context_path.last == 'habitat'
        "/#{File.join(plan_context_path)}"
      end

      all_dirs.uniq
    end

    #
    # search the workspace repo for any plan.sh files inside of habitat
    # directories, and return an array of paths to the plan_context for each
    # service. This will return an array sorted lexigraphically.
    #
    # Example:
    # Let's assume you have multiple habitat PLAN_CONTEXTs in a single repository
    #
    # $ tree .
    #   .
    #   ├── service-one
    #   |   ├── habitat
    #   |   |   ├── plan.sh
    #   ├── service-two
    #   |   ├── habitat
    #   |   |   ├── plan.sh
    #   ├── habitat-plans
    #   |   ├── nested-service
    #   |   |   ├── plan.sh
    #
    # This helper will return the following array:
    # => [
    #     "/src/service-one/habitat",
    #     "/src/service-two/habitat",
    #     "/src/habitat-plans/nested-service"
    #    ]
    #
    def detect_plan_dirs
      Dir.glob(File.join(workflow_workspace_repo, '**/**/plan.sh')).map do |dir|
        Pathname(dir.sub(workflow_workspace_repo, '/src')).dirname.to_s
      end
    end

    #
    # Return a list of fully-qualified paths to habitat PLAN_CONTEXTs that have
    # been modified in the current change.
    #
    # `changed_dirs` comes from the delivery-sugar DSL, and will return a list of
    # all the directories (down to the deepest child) that have been modified. We
    # do a union with our list of plan_contexts to determine which Habitat packages
    # need to be rebuilt.
    #
    def modified_habitat_plan_contexts
      habitat_plan_contexts & changed_dirs.map { |changed_dir| Pathname("/src/#{changed_dir}").cleanpath.to_s }
    end

    def habitat_origin_key?
      project_secrets_exist?(%w(keyname private_key public_key))
    end

    def habitat_depot_token?
      project_secrets_exist?(%w(depot_token))
    end

    def hab_binary
      if platform_family?('mac_os_x')
        '/usr/local/bin/hab'
      else
        '/bin/hab'
      end
    end

    def habitat_plan_dir_specified?
      node['delivery']['config'].attribute?('habitat') &&
        node['delivery']['config']['habitat'].attribute?('plan_dir')
    end

    def changed_habitat_files?
      modified_habitat_plan_contexts.any?
    end

    # if we're going to load secrets, we need to make sure we actually
    # have the data!
    def project_secrets_exist?(secret_keys = [])
      begin
        key_data = get_project_secrets.to_hash
      rescue Net::HTTPServerException
        return false
      end

      return false unless key_data.key?('habitat') && !key_data['habitat'].empty?

      secret_keys.each do |req_key|
        next if key_data['habitat'].key?(req_key) && !key_data['habitat'][req_key].empty?
        return false
      end

      true
    end
  end
end

Chef::Recipe.send(:include, HabitatBuildCookbook::Helpers)
Chef::Resource.send(:include, HabitatBuildCookbook::Helpers)
