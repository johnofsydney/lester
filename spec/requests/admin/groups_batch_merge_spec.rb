require 'rails_helper'

RSpec.describe 'Admin::Groups batch merge', type: :request do
  let(:admin_user) { create(:admin_user) }

  before { sign_in admin_user, scope: :admin_user }

  def batch_merge(groups, target_group_id:)
    post batch_action_admin_groups_path, params: {
      batch_action: 'merge_selected',
      collection_selection: groups.map(&:id),
      batch_action_inputs: { target_group_id: target_group_id }.to_json
    }
  end

  it 'merges the selected groups into the target group' do
    allow(Cache::BuildGroupCachedDataJob).to receive(:perform_async)

    target = create(:group)
    source_a = create(:group)
    source_b = create(:group)

    expect { batch_merge([source_a, source_b], target_group_id: target.id) }
      .to change(Group, :count).by(-2)

    expect(Group.exists?(source_a.id)).to be false
    expect(Group.exists?(source_b.id)).to be false
    expect(response).to redirect_to(admin_group_path(target))
    expect(flash[:notice]).to include(source_a.name).and include(source_b.name).and include(target.name)
    expect(Cache::BuildGroupCachedDataJob).to have_received(:perform_async).with(target.id).twice
  end

  it 'reports an error and merges nothing when the target group id is missing' do
    source = create(:group)

    expect { batch_merge([source], target_group_id: '') }.not_to change(Group, :count)
    expect(response).to redirect_to(admin_groups_path)
    expect(flash[:alert]).to include('not found')
  end

  it 'skips the target group if it is included in the selection, without error' do
    allow(Cache::BuildGroupCachedDataJob).to receive(:perform_async)

    target = create(:group)
    source = create(:group)

    expect { batch_merge([target, source], target_group_id: target.id) }
      .to change(Group, :count).by(-1)

    expect(Group.exists?(target.id)).to be true
    expect(Group.exists?(source.id)).to be false
    expect(Cache::BuildGroupCachedDataJob).to have_received(:perform_async).with(target.id)
  end

  it 'preserves the standard merge guardrails, reporting the blocked group without merging it' do
    allow(Cache::BuildGroupCachedDataJob).to receive(:perform_async)

    target = create(:group, business_number: '123456789')
    blocked = create(:group, business_number: '987654321')
    mergeable = create(:group)

    expect { batch_merge([blocked, mergeable], target_group_id: target.id) }
      .to change(Group, :count).by(-1)

    expect(Group.exists?(blocked.id)).to be true
    expect(Group.exists?(mergeable.id)).to be false
    expect(flash[:alert]).to include(blocked.name).and include('Failed')
    expect(Cache::BuildGroupCachedDataJob).to have_received(:perform_async).with(target.id)
  end
end
