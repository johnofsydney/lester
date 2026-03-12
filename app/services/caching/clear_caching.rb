class Caching::ClearCaching
  def self.call
    new.call
  end

  def call
    Group.update_all(cached_data: {}) && Person.update_all(cached_data: {}) # rubocop:disable Rails/SkipsModelValidations
  end
end
