require 'spec_helper'
require_relative '../../../libraries/helpers'

describe 'test::detect' do
  let(:cli_node) do
    {
      'delivery_builder' => {
        'build_user' => 'dbuild',
      },
      'delivery' => {
        'workspace_path' => '/workspace',
        'workspace' => {
          'repo' => '/workspace/path/to/phase/repo',
          'cache' => '/workspace/path/to/phase/cache',
          'chef' => '/workspace/path/to/phase/chef',
        },
        'change' => {
          'stage' => 'stage',
          'enterprise' => 'ent',
          'organization' => 'org',
          'project' => 'proj',
          'change_id' => 'id',
          'pipeline' => 'pipe',
          'patchset_branch' => 'branch',
          'sha' => 'sha',
        },
      },
    }
  end

  let(:changed_dirs) do
    [
      '.',
      'test/fixtures/plans/plan-a',
      'test/fixtures/plans/plan-b',
    ]
  end

  before do
    allow_any_instance_of(Chef::Recipe).to receive(:changed_dirs).and_return(changed_dirs)
  end

  context 'when the user specifies a single plan context in config.json' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(
        platform: 'redhat',
        version: '7'
      ) do |node|
        node.normal['delivery'] = cli_node['delivery']
        node.normal['delivery_builder'] = cli_node['delivery_builder']
        node.default['delivery']['config']['habitat']['plan_dir'] = '/src/test/fixtures/plans/plan-a'
      end.converge(described_recipe)
    end

    it 'builds that plan context' do
      expect(chef_run).to build_hab_build('plan-a').with(
        plan_dir: '/src/test/fixtures/plans/plan-a'
      )
    end
  end

  context 'when the user specifies multiple plan contexts in config.json' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(
        platform: 'redhat',
        version: '7'
      ) do |node|
        node.normal['delivery'] = cli_node['delivery']
        node.normal['delivery_builder'] = cli_node['delivery_builder']
        node.default['delivery']['config']['habitat']['plan_dir'] = [
          '/src/test/fixtures/plans/plan-a',
          '/src/test/fixtures/plans/plan-b/habitat',
        ]
      end.converge(described_recipe)
    end

    it 'builds those contexts in order' do
      expect(chef_run).to build_hab_build('plan-a').with(
        plan_dir: '/src/test/fixtures/plans/plan-a'
      )
      expect(chef_run).to build_hab_build('plan-b').with(
        plan_dir: '/src/test/fixtures/plans/plan-b'
      )
    end
  end

  context 'when the user does not specify any plan contexts' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(
        platform: 'redhat',
        version: '7'
      ) do |node|
        node.normal['delivery'] = cli_node['delivery']
        node.normal['delivery_builder'] = cli_node['delivery_builder']
        node.default['delivery']['config'] = {}
      end.converge(described_recipe)
    end

    before do
      allow(Dir).to receive(:glob).with('/workspace/path/to/phase/repo/**/**/plan.sh').and_return(
        [
          '/workspace/path/to/phase/repo/habitat/plan.sh',
          '/workspace/path/to/phase/repo/test/fixtures/plans/plan-a/plan.sh',
          '/workspace/path/to/phase/repo/test/fixtures/plans/plan-b/habitat/plan.sh',
          '/workspace/path/to/phase/repo/test/fixtures/plans/plan-c/plan.sh',
        ]
      )
    end

    it 'searches for contexts in the repo' do
      # When building a hab pkg in root, we name it after the project
      expect(chef_run).to build_hab_build('proj').with(
        plan_dir: '/src'
      )
      expect(chef_run).to build_hab_build('plan-a').with(
        plan_dir: '/src/test/fixtures/plans/plan-a'
      )
      expect(chef_run).to build_hab_build('plan-b').with(
        plan_dir: '/src/test/fixtures/plans/plan-b'
      )
      # Plan C was not modified, so do not build it
      expect(chef_run).not_to build_hab_build('plan-c').with(
        plan_dir: '/src/test/fixtures/plans/plan-c'
      )
    end
  end
end
