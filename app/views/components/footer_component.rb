class FooterComponent < ApplicationView
  def view_template
    case Current.host
    when /michaelwest/
      render partial('shared/mwm_footer_file')
    end
  end
end
