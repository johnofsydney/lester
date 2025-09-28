class MapGroupNamesGeneral < MapGroupNamesBase
  def call(name)
    map_or_return_name(name)
  end

  def map_or_return_name(name)
    raise 'Name is required' if name.blank?

    name = name.gsub(/\s+/, ' ').strip

    cleaned_up_name(name)
  end
end