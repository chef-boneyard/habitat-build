#
# Cookbook:: habitat-build
# Recipe:: lint
#
# Copyright:: 2016-2019, Chef Software Inc.
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

execute 'lint-check-plan' do
  # by targetting bash, we avoid warning on SC2148
  # https://github.com/koalaman/shellcheck/wiki/SC2148
  command "find . -name 'plan.sh' -exec shellcheck -e #{node['habitat-build']['shellcheck-excludes'].join(',')} -s bash {} \\;"
  cwd node['delivery']['workspace']['repo']
end
