# habitat-build

A build cookbook for running the parent project through Chef Delivery

This build cookbook should be customized to suit the needs of the parent project. Do this by "wrapping" the cookbook as a dependency in your project's build cookbook.

Add to your build cookbook's metadata.rb:

```ruby
depends 'delivery-sugar'
depends 'delivery_build'
depends 'habitat-build'
depends 'delivery-truck'
```

Add to your build cookbook's Berksfile:

```ruby
source "https://supermarket.chef.io"

metadata

cookbook 'delivery-truck'

cookbook 'delivery-base',  git: 'https://github.com/chef-cookbooks/delivery-base.git'
cookbook 'delivery_build', git: 'https://github.com/chef-cookbooks/delivery_build.git'
cookbook 'delivery-sugar', git: 'https://github.com/chef-cookbooks/delivery-sugar.git'
cookbook 'habitat-build',  git: 'https://github.com/chef-cookbooks/habitat-build.git'
```

Include `habitat-build` recipes in your build cookbook's phase
recipes. For example in your build cookbook's `lint` recipe:

```ruby
include_recipe 'habitat-build::lint'
```

Your project must have a `./habitat` directory that contains the `plan.sh` file and other files as necessary for your project to be packaged by Habitat - for example `default.toml`, or the run script.

## Attributes

`node['habitat-build']['depot-url']` URL to the Habitat Depot where packages are published.

`node['habitat-build']['hab-pkgident']` Package identifier for the `core/hab` package.

`node['habitat-build']['hab-studio-pkgident']` Package identifier for the `core/hab-studio` package.

`node['habitat-build']['shellcheck-excludes']` `Array` of ShellCheck codes to [ignore](https://github.com/koalaman/shellcheck/wiki/Ignore).

## Recipes

### default

Sets up a Chef Delivery build node so that it can build Habitat packages in a Studio.

### deploy

Does nothing in this cookbook.

### functional

Does nothing in this cookbook.

### lint

Performs a [lint check](https://en.wikipedia.org/wiki/Lint_(software) against the `habitat/plan.sh` using the [ShellCheck](https://www.shellcheck.net/) static analysis tool. Specific codes can be ignored by ShellCheck by adding them to the node attribute array, `node['habitat-build']['shellcheck-excludes']`.

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

### client

The `habitat-client` Ruby library. This is in the cookbook because we cannot publish it as a RubyGem until we release Habitat to the world. See rdoc comments in `libraries/client.rb` for more information.

### exceptions

Custom exception handlers for `habitat-client`.

### helpers

Cookbook recipe helper methods.

`habitat_plan_dir`: returns the directory where the plan lives. Searches the `delivery/config.json` of the build cookbook configuration, followed by an attribute, and falls back to `/src/habitat`.

`habitat_secrets?`: predicate method that returns `true` if there's a data bag item for the project's secrets in Chef Delivery, and if it has non-empty origin secrets in a hash key `habitat`, `keyname`, `private_key`, `public_key`, and `depot_token`.

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
