class Common::TableRow < ApplicationView
	def initialize(hentity:)
		@hentity = hentity
	end

 attr_reader :hentity

 def view_template
   tr(class: ended_membership? ? 'fst-italic' : nil) do
     td do
       span { link_for_hash(h: hentity) }
     end
     td do
       span do
        hentity['last_position'].present? ? Nodes::NameCapitalizer.capitalize(hentity['last_position']) : ''
       end
     end
   end
 end

  private

 def ended_membership?
   hentity['current'] == false
 end
end
