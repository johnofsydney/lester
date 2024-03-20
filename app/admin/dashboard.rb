# frozen_string_literal: true
ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    # div class: "blank_slate_container", id: "dashboard_default_message" do
    #   span class: "blank_slate" do
    #     span I18n.t("active_admin.dashboard_welcome.welcome")
    #     small I18n.t("active_admin.dashboard_welcome.call_to_action")
    #   end
    # end

    # Here is an example of a simple dashboard with columns and panels.
    #
    columns do
      column do
        panel "Recent People" do
          ul do
            Person.order(created_at: :desc).last(10).map do |person|
              li link_to(person.name, admin_person_path(person))
            end
          end
        end
        panel "Recent Suggestions" do
          ul do
            Suggestion.order(created_at: :desc).last(10).map do |suggestion|
              li link_to(suggestion.headline, admin_suggestion_path(suggestion))
              ul do
                li suggestion.description
                li suggestion.evidence
                li suggestion.suggested_by
              end

            end
          end
        end
      end

      column do
        panel "Info" do
          para "Welcome to ActiveAdmin."
          link_to 'Button Name', 'http://example.com', target: '_blank'
        end
          attributes_table_for '' do
            row('Import Data') do
              link_to('Import Data', '/imports')
            end
          end

      end
    end
  end # content

end
