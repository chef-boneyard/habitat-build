# This is an example plan that does nothing, just produces a Habitat Artifact
# that can be used for testing purposes.
pkg_origin=build-cookbook
pkg_name=pandas
pkg_version=0.0.1
pkg_maintainer="The Habitat Maintainers <humans@habitat.sh>"
pkg_license=('apache2')
pkg_source=http://example.com/${pkg_name}-${pkg_version}.tar.xz
pkg_shasum=sha256sum
pkg_bin_dirs=(bin)
pkg_include_dirs=(include)
pkg_lib_dirs=(lib)
pkg_gpg_key=3853DA6B

do_begin() {
  return 0
}

do_unpack() {
  return 0
}

do_download() {
  return 0
}

do_verify() {
  return 0
}

do_install() {
  return 0
}

do_build() {
  return 0
}

do_prepare() {
  return 0
}
