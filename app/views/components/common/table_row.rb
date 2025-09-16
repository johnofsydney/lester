class Common::TableRow < ApplicationView
	def initialize(hentity:)
		@hentity = hentity
	end

  attr_reader :hentity

  def template
    tr do
      td do
        span { link_for_hash(h: hentity) }
      end
      td do
        span {hentity['last_position'] || ''}
      end
    end
  end
end
