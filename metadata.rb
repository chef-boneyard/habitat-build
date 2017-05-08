name 'habitat-build'
maintainer 'The Habitat Maintainers'
maintainer_email 'humans@habitat.sh'
license 'apache2'
version '0.14.0'

depends 'delivery-sugar'
depends 'delivery-truck'

# Until the resources go into core Chef, use the cookbook:
depends 'habitat', '>= 0.1.0'

issues_url 'https://github.com/habitat-sh/habitat-build-cookbook/issues'
source_url 'https://github.com/habitat-sh/habitat-build-cookbook'
