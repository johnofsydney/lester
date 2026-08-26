require 'rails_helper'

# Proper-casing the shouty surname is deliberately NOT this service's job -- that happens
# downstream via CapitalizeNames when People::RecordPerson.clean_name is applied on top (see
# RecordCandidatePerson). This service only fixes the surname-first token ordering.
RSpec.describe NswStatePoliticians::CleanCandidateName, type: :service do
  it 'swaps a simple SURNAME Given name' do
    expect(described_class.call('VOLTZ Lynda')).to eq('Lynda VOLTZ')
  end

  it 'handles a multi-word surname' do
    expect(described_class.call('MORKOS DOUAIHY Julie')).to eq('Julie MORKOS DOUAIHY')
  end

  it 'handles a parenthetical given name' do
    expect(described_class.call('ZAMAN Mohammed (Haseen)')).to eq('Mohammed (Haseen) ZAMAN')
  end

  it 'handles an apostrophe in the all-caps surname' do
    expect(described_class.call("O'BRIEN Jane")).to eq("Jane O'BRIEN")
  end
end
