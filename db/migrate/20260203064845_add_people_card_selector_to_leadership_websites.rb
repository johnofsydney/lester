class AddPeopleCardSelectorToLeadershipWebsites < ActiveRecord::Migration[8.0]
  def change
    add_column :leadership_websites, :people_card_selector, :text
  end
end
