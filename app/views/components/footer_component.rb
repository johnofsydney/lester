class FooterComponent < ApplicationView
  def view_template
    case Current.host
    when /localhost/
      render partial('shared/mwm_footer_file')
    else

    end
  end
end
