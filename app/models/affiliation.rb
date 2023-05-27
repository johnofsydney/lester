class Affiliation < ApplicationRecord
  belongs_to :owning_group, class_name: 'Group'
  belongs_to :sub_group, class_name: 'Group'

  # ...
end