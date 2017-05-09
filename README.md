# habitat-build

A build cookbook for running the parent project through Chef Automate.

This build cookbook should be customized to suit the needs of the parent project. Do this by "wrapping" the cookbook as a dependency in your project's build cookbook.

## Requirements

Your project must have at least one of the following:
  * a `habitat` directory that contains the `plan.sh` file and other files (as necessary) for your project to be packaged by Habitat
  * a service directory that contains the `plan.sh` file (e.g. the format found in [habitat-sh/core-plans](https://github.com/habitat-sh/core-plans))

## Setup

Add to your build cookbook's metadata.rb:

```ruby
depends 'habitat-build'
```

Add to your build cookbook's Berksfile:

```ruby
source "https://supermarket.chef.io"

metadata

cookbook 'habitat-build',  git: 'https://github.com/chef-cookbooks/habitat-build.git'
```

Include `habitat-build` recipes in your build cookbook's phase recipes. For example in your build cookbook's `lint` recipe:

```ruby
include_recipe 'habitat-build::lint'
```

## Usage Patterns

### My entire project is dedicated to a single Habitat package

This is the recommended pattern when using this build cookbook. If you use this pattern, no additional steps are required! Simply include the appropriate `habitat-build` recipes in your build cookbook's phase recipes and carry on! For example in your build cookbook's `lint` recipe:

```ruby
include_recipe 'habitat-build::lint'
```

### My project has multiple standalone Habitat contexts inside it

This pattern would apply if your project repo contains multiple Habitat plans, but a change to one plan does not necessitate that you rebuild another. An example of this would be the [habitat-sh/core-plans](https://github.com/habitat-sh/core-plans). If you are using this pattern, no additional steps are required! Simply include the appropriate `habitat-build` recipes in your build cookbook's phase recipes and carry on! For example in your build cookbook's `publish` recipe:

```ruby
include_recipe 'habitat-build::publish'
```

### My project has multiple interdependent Habitat contexts inside it

This pattern would apply if your project repo contains multiple Habitat plans, some of which have inter-dependencies that require that when one is rebuilt so must another, or the execution of the Habitat builds must occur in a specific order. This is a pattern you might find yourself in if you're working with an application that is a monolith. In this case, you can still use the `default`, `lint`, and `syntax` recipes as is but you'll need to use the helpers outlined below to custom build your own `publish` and `provision` recipes. If this is your current scenario, we encourage you to familiarize yourself with the recipes and helpers in this cookbook and leverage them in the way that best suites your needs.

## Attributes

* `node['habitat-build']['depot-url']`: URL to the Habitat Depot where packages are published.
* `node['habitat-build']['shellcheck-excludes']`: `Array` of ShellCheck codes to [ignore](https://github.com/koalaman/shellcheck/wiki/Ignore).

## Recipes

### default

Sets up a Chef Automate build node so that it can build Habitat packages in a Studio.

### deploy

Does nothing in this cookbook.

### functional

Does nothing in this cookbook.

### lint

Performs a [lint check](https://en.wikipedia.org/wiki/Lint_\(software\)) against the `habitat/plan.sh` using the [ShellCheck](https://www.shellcheck.net/) static analysis tool. Specific codes can be ignored by ShellCheck by adding them to the node attribute array, `node['habitat-build']['shellcheck-excludes']`.

**Note**: This attribute will become a Delivery `config.json` option.

### provision

This recipe loads the information from the data bag generated in the `publish` phase and uses that to promote the artifact the current Delivery stage in Acceptance, Union, Rehearsal, and Delivered stages. It will then be available from the depot for that view in other phases in the stage.

### publish

This recipe builds the package with Habitat and publishes it to the configured Habitat Depot (by default, the public Habitat Depot). Change the `node['habitat-build']['depot-url']` to an internal depot if necessary. Once the build is complete, this recipe uses the `/src/results/last_build.env` file for information about the package that was built. It uses `hab artifact hash` to generate the hash checksum for the package. The information gathered is stored in a data bag, named after the Delivery `project_slug`, which is generated as `enterprise-organization-project` by Delivery. The item itself will have a timestamp name like `2016-06-01_1643`.

This data bag item is used in the `provision` recipe to track state changes of the build through the pipeline, as each phase is a separate Chef Client run on the build node.

### quality

Does nothing in this cookbook.

### security

Does nothing in this cookbook.

### smoke

Does nothing in this cookbook.

### syntax

Performs a `bash` syntax check using `bash -n` against the `habitat/plan.sh`.

### unit

Does nothing in this cookbook.

## Libraries

### helpers

Cookbook recipe helper methods.

`habitat_plan_dir`: returns the directory where the plan lives. Searches the `delivery/config.json` of the build cookbook configuration, followed by an attribute, and falls back to `/src/habitat`.

`habitat_plan_contexts`: returns a list of Habitat plan contexts in your project repository. If you specify a list of directories in your `.delivery/config.json` file under the `habitat['plan_dir']` key, it will return the list of corresponding plan contexts. Otherwise, it searches the project for Habitat plan files and returns an array of Habitat plan contexts that it can find (as determined by the presence of a `plan.sh` file). See the comment in the `helpers.rb` library for more information.

`modified_habitat_plan_contexts`: returns a list of `habitat_plan_contexts` that were modified in the current change set.

`habitat_origin_key?`: predicate method that returns `true` if there's a data bag item for the project's secrets in Chef Delivery, and if it has non-empty origin secrets in a hash key `habitat`, `keyname`, `private_key`, `public_key`.

`habitat_depot_token?`: predicate method that returns `true` if there's a data bag item for the project's secrets in Chef Delivery, and if it has non-empty origin secrets in a hash key `habitat`, `depot_token`.

## Local Development

If you have [ChefDK](https://downloads.chef.io/chefdk) installed you can run
the unit, lint, and syntax checks against this cookbook locally with `delivery
local verify`.

## License and Author

- Author: Joshua Timberman <joshua@chef.io>
- Copyright (C) 2014-2015 Chef Software, Inc. <legal@chef.io>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
