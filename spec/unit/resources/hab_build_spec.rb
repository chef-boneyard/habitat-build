require 'spec_helper'
require_relative '../../../libraries/helpers'

describe 'test::publish' do
  describe ':publish action' do
    before do
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(
        '/hab/studios/testproject-teststage-testphase/src/results/last_build.env'
      ).and_return(<<-EOF
pkg_origin=purple
pkg_name=frogs
pkg_version=0.7.0-dev
pkg_release=20170403213025
pkg_ident=purple/frogs/0.7.0-dev/20170403213025
pkg_artifact=purple-frogs-0.7.0-dev-20170403213025-x86_64-linux.hart
pkg_sha256sum=f879e8f7191f07f51f394d574b26611e820161114987123878d327f2ae64dab8
pkg_blake2bsum=17d058114159f2a5dbc6ffea2d1526f89b33944bbd9fd75cec79c97e10d4d2dd
EOF
                  )
    end

    cached(:chef_run) do
      ChefSpec::SoloRunner.new(
        step_into: ['hab_build'],
        platform: 'redhat',
        version: '7.2'
      ).converge(described_recipe)
    end

    it 'builds the package with hab studio' do
      expect(chef_run).to run_execute('build-plan').with(
        command: 'sudo -E /bin/hab studio -r /hab/studios/testproject-teststage-testphase build /src/pandas',
        environment: hash_including('ABC' => 'XYZ',
                                    'HAB_NONINTERACTIVE' => 'true')
      )
    end

    it 'uploads the artifact with hab pkg upload' do
      expect(chef_run).to run_execute('upload-pkg').with(
        command: '/bin/hab pkg upload  /hab/studios/testproject-teststage-testphase/src/results/purple-frogs-0.7.0-dev-20170403213025-x86_64-linux.hart'
      )
    end
  end
end

describe 'test::upload' do
  before do
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with(
      '/hab/studios/testproject-teststage-testphase/src/results/last_build.env'
    ).and_return(<<-EOF
pkg_origin=purple
pkg_name=frogs
pkg_version=0.7.0-dev
pkg_release=20170403213025
pkg_ident=purple/frogs/0.7.0-dev/20170403213025
pkg_artifact=purple-frogs-0.7.0-dev-20170403213025-x86_64-linux.hart
pkg_sha256sum=f879e8f7191f07f51f394d574b26611e820161114987123878d327f2ae64dab8
pkg_blake2bsum=17d058114159f2a5dbc6ffea2d1526f89b33944bbd9fd75cec79c97e10d4d2dd
EOF
                )
  end
  cached(:chef_run) do
    ChefSpec::SoloRunner.new(
      step_into: ['hab_build'],
      platform: 'redhat',
      version: '7.2'
    ).converge(described_recipe)
  end

  it 'uploads an artifact with a custom depot URL' do
    expect(chef_run).to publish_hab_build('upload-with-url').with(
      depot_url: 'https://private-depot.example.com/v1/depot'
    )
    expect(chef_run).to run_execute('upload-pkg').with(
      command: '/bin/hab pkg upload --url https://private-depot.example.com/v1/depot /hab/studios/testproject-teststage-testphase/src/results/purple-frogs-0.7.0-dev-20170403213025-x86_64-linux.hart'
    )
  end
end
