require 'rails_helper'

RSpec.describe Attributable do
  after { Current.reset }

  it "attributes to 'system' when no admin user is current" do
    person = Person.create!(name: 'Jane System')

    expect(person.attributed_to).to eq('system')
  end

  it 'attributes to the current admin user email when present' do
    admin_user = AdminUser.create!(email: 'reviewer@example.com', password: 'password12345')
    Current.user = admin_user

    person = Person.create!(name: 'Jane Admin')

    expect(person.attributed_to).to eq('reviewer@example.com')
  end

  it 'does not overwrite an explicitly set attributed_to' do
    person = Person.create!(name: 'Jane Explicit', attributed_to: 'import_script')

    expect(person.attributed_to).to eq('import_script')
  end

  it "attributes a Group to 'system' when no admin user is current" do
    group = Group.create!(name: 'Some Org')

    expect(group.attributed_to).to eq('system')
  end
end
