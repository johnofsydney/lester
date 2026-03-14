module People
  extend ActiveSupport::Concern

  module Regexp
    PREFIX_TITLES = /^(Mr|Ms|Mrs|Dr)\.?\s+/i
  end
end