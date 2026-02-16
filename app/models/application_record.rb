class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # TODO: is this worth doing at work?
  def self.ransackable_attributes
    authorizable_ransackable_attributes
  end

  def self.ransackable_associations
    authorizable_ransackable_associations
  end
end
