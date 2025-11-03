class FooterComponent < ApplicationView
  def initialize
  end

  def view_template
    footer(class: "py-3 my-4") do
      ul(class: "nav justify-content-center border-bottom pb-3 mb-3") do
        li(class: "nav-item") { a(href: "#", class: "nav-link px-2 text-body-secondary") { "Home" } }
        li(class: "nav-item") { a(href: "#", class: "nav-link px-2 text-body-secondary") { "Features" } }
        li(class: "nav-item") { a(href: "#", class: "nav-link px-2 text-body-secondary") { "Pricing" } }
        li(class: "nav-item") { a(href: "#", class: "nav-link px-2 text-body-secondary") { "FAQs" } }
        li(class: "nav-item") { a(href: "#", class: "nav-link px-2 text-body-secondary") { "About" } }
      end
      p(class: "text-center text-body-secondary") { "© 2025 Company, Inc" }
    end
  end
end
