# By default we use the public Habitat Depot
default['habitat-build']['depot-url'] = 'http://willem.habitat.sh:9636/v1/depot'

# TODO: (jtimberman) Maybe we can discover these at some point, but it
# really doesn't matter - these are in the depot now, and will be
# available forevermore. Until they're not. And then we'll update
# these attributes.
default['habitat-build']['hab-pkgident'] = 'core/hab/0.5.0/20160520164554'
default['habitat-build']['hab-static-pkgident'] = 'core/hab-static/0.5.0/20160520164154'
default['habitat-build']['hab-studio-pkgident'] = 'core/hab-studio/0.5.0/20160520171253'

# An array of codes to ignore in shellcheck (lint checker). By default
# we exclude:
#
#   * SC2034 - the variables we set are not used in the plan.sh
#              https://github.com/koalaman/shellcheck/wiki/SC2034
default['habitat-build']['shellcheck-excludes'] = ['SC2034']
