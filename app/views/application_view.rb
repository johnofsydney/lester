# frozen_string_literal: true

class ApplicationView < ApplicationComponent
	# The ApplicationView is an abstract class for all your views.

	# By default, it inherits from `ApplicationComponent`, but you
	# can change that to `Phlex::HTML` if you want to keep views and
	# components independent.

  def element_styles(instance, style = '')
    {
      'background_color' => background_color(instance),
      'color' => color(instance),
    }.map{|key, value| "#{key.to_s.dasherize}: #{value};"}
     .join('; ') + style + ';'
  end
  def button_styles(instance, depth = 0)

    background_color = depth.zero? ? background_color(instance) : color(instance)
    color = depth.zero? ? color(instance) : background_color(instance)

    {
      'background_color' => background_color(instance),
      'color' => color(instance),
      'display' => 'inline-block',
      'margin' => '0.25rem',
      'padding'=> '0.25rem',
    }.map{|key, value| "#{key.to_s.dasherize}: #{value};"}
     .join('; ') + ';'

  end

  def background_color(item)
    background_color = safe_name(item)
    "#" + text_to_hex(background_color)
  end

  def color(item)
    text_to_hex(safe_name(item)).hex > 0x7FFFFF ? 'black' : 'white'
  end

  def text_to_hex(text)
    Digest::MD5.hexdigest(text)[0..5]
  end

  def safe_name(item)
    item.attributes['name'] || item.attributes['amount'].to_s
  end

  def class_of(entity)
    if entity.respond_to?(:klass)
      return 'people' if entity&.klass == 'Person'
      return 'groups' if entity&.klass == 'Group'
    end

    return 'groups' if entity.respond_to?(:report_as) && entity.report_as == 'group' # special case for summary rows
    return 'transfers' if entity.is_a?(Transfer)

    entity.is_a?(Group) ? 'groups' : 'people'
  end

  # entity: the object to link to
  # class: the CSS class to use
  # style: the CSS style to use
  # link_text: the text to display in the link
  # action: the action to append to the link
  def link_for(entity:, class: '', style: '', link_text: nil, action: nil, klass: nil)
    klass_name_plural = if klass.present?
                          klass.to_s.pluralize.downcase
                        else
                          class_of(entity)
                        end
    id = entity.id
    link_text ||= entity.respond_to?(:name) ? entity.name : entity.amount
    href = "/#{klass_name_plural}/#{id}"

    href += "/#{action}" if action

    a(href: href, class:, style:) { link_text }
  end
end
