class Common::PleaseRefreshLater < ApplicationView

  def initialize

  end

  def view_template
    div(class: 'alert alert-info text-center') do
      p { "This data is being prepared. Please refresh this page in a minute or two to see the updated information." }
    end
  end
end