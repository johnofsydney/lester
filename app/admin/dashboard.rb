# frozen_string_literal: true

ActiveAdmin.register_page 'Dashboard' do
  menu priority: 1, label: proc { I18n.t('active_admin.dashboard') }

  action_item :clear_group_and_people_cache do
    link_to 'Clear Group and People Cache', admin_dashboard_clear_group_and_people_cache_path
  end

  page_action :clear_group_and_people_cache, method: :get do
    raise unless current_admin_user

    Caching::ClearCaching.call
    redirect_to admin_dashboard_path, notice: 'Group and People cache cleared.'
  end

  content title: proc { I18n.t('active_admin.dashboard') } do
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
        panel 'Recent People' do
          ul do
            Person.order(created_at: :desc).last(10).map do |person|
              li link_to(person.name, admin_person_path(person))
            end
          end
        end
        panel 'Recent Groups' do
          ul do
            Group.order(created_at: :desc).last(10).map do |group|
              li link_to(group.name, admin_group_path(group))
            end
          end
        end
      end

      column do
        panel 'Info' do
          para 'Welcome to ActiveAdmin.'
          link_to 'Button Name', 'http://example.com', target: '_blank', rel: 'noopener'
        end
      end
    end
  end # content
end
