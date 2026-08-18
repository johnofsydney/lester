require 'rails_helper'

RSpec.describe 'Admin::Groups batch destroy', type: :request do
  let(:admin_user) { create(:admin_user) }

  before { sign_in admin_user, scope: :admin_user }

  def batch_destroy(groups)
    post batch_action_admin_groups_path, params: {
      batch_action: 'destroy',
      collection_selection: groups.map(&:id),
      batch_action_inputs: '{}'
    }
  end

  it 'destroys groups with no memberships or transfers' do
    group = create(:group)

    expect { batch_destroy([group]) }.to change(Group, :count).by(-1)
    expect(response).to redirect_to(admin_groups_path)
    expect(flash[:notice]).to eq('Groups deleted successfully.')
  end

  it 'refuses to destroy a group that is a member of another group, leaving no orphaned Membership' do
    parent = create(:group)
    child = create(:group)
    create(:membership, member: child, group: parent)

    expect { batch_destroy([child]) }.not_to change(Group, :count)
    expect(Membership.where(member: child).count).to eq(1)
    expect(response).to redirect_to(admin_groups_path)
    expect(flash[:alert]).to include(child.name)
  end

  it 'refuses to destroy a group that owns memberships' do
    group = create(:group)
    create(:membership, member: create(:person), group: group)

    expect { batch_destroy([group]) }.not_to change(Group, :count)
    expect(flash[:alert]).to include(group.name)
  end

  it 'refuses to destroy a group with transfers' do
    group = create(:group)
    Transfer.create!(giver: group, taker: create(:person), amount: 100, effective_date: Date.new(2020, 1, 1), transfer_type: 'donations')

    expect { batch_destroy([group]) }.not_to change(Group, :count)
    expect(flash[:alert]).to include(group.name)
  end

  it 'deletes the allowed groups and reports the blocked ones when selection is mixed' do
    deletable = create(:group)
    parent = create(:group)
    blocked = create(:group)
    create(:membership, member: blocked, group: parent)

    expect { batch_destroy([deletable, blocked]) }.to change(Group, :count).by(-1)
    expect(Group.exists?(deletable.id)).to be false
    expect(Group.exists?(blocked.id)).to be true
    expect(flash[:alert]).to include(blocked.name)
  end
end
