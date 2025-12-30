class FooterComponent < ApplicationView
  def view_template
    case Current.host
    when /michaelwest/
      render partial('shared/mwm_footer_file')
    else
      # nothing
    end
  end
end
