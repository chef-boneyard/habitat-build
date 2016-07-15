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
# By default we use the public Habitat Depot
#
# TODO: (jtimberman) Configure this from a Delivery `config.json`.
default['habitat-build']['depot-url'] = 'https://willem.habitat.sh/v1/depot'

# TODO: (jtimberman) Maybe we can discover these at some point, but it
# really doesn't matter - these are in the depot now, and will be
# available forevermore. Until they're not. And then we'll update
# these attributes.
default['habitat-build']['hab-pkgident'] = 'core/hab/0.7.0/20160614230104'

# An array of codes to ignore in shellcheck (lint checker). By default
# we exclude:
#
#   * SC2034 - the variables we set are not used in the plan.sh
#              https://github.com/koalaman/shellcheck/wiki/SC2034
#
# TODO: (jtimberman) use this with the Delivery `config.json` data so
# it's easier for users to modify.
default['habitat-build']['shellcheck-excludes'] = ['SC2034']
