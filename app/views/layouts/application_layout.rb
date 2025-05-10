# frozen_string_literal: true

class ApplicationLayout < ApplicationView
	include Phlex::Rails::Layout

	def template(&block)
		doctype

		html do
			head do
				title { 'Follow The Money' }
				meta name: 'viewport', content: 'width=device-width,initial-scale=1'
				csp_meta_tag
				csrf_meta_tags

        link(rel: 'stylesheet', href: 'https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.0.1/css/bootstrap.min.css')

				stylesheet_link_tag 'application', data_turbo_track: 'reload'
				javascript_importmap_tags
			end

			body(class: 'container') do
        render MenuComponent.new
				main(&block)

			end
		end
	end
end
