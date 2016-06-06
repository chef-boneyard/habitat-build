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
