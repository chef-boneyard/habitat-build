name 'habitat-build'
maintainer 'The Habitat Maintainers'
maintainer_email 'humans@habitat.sh'
license 'apache2'
version '0.10.6'

depends 'delivery-sugar'
depends 'delivery-truck'

# Until the resources go into core Chef, use the cookbook:
depends 'habitat', '>= 0.1.0'

gem 'habitat-client'

issues_url 'https://github.com/habitat-sh/habitat-build-cookbook/issues'
source_url 'https://github.com/habitat-sh/habitat-build-cookbook'
