module Watir
  module Container

    class << self

      private

      # @!macro support_element
      #   @!method $1
      #   Create an $1 html element instance.
      #
      #   Elements can be searched by using different locators.
      #   
      #   @example Search by partial text:
      #     browser.$1(:text => /partial text/)
      #   
      #   @example Search by id:
      #     browser.$1(:id => "htmlid")
      #
      #   @example Search by any arbitrary html attribute:
      #     browser.$1(:foo => "value-of-foo-attribute")
      #
      #   @example Search by multiple attributes, all provided locators should evaluate to true - only then element is considered to be found:
      #     browser.$1(:text => "some text", :class => "css class")
      #
      #   @example It is also possible to search for multiple elements of the same type like this:
      #     browser.divs(:class => "foo") # => instance of Watir::DivCollection
      def support_element(method_name, args={})
        klass = args[:class] || method_name.to_s.capitalize
        super_class = args[:super_class] || "Element"

        unless Watir.const_defined? klass
          Watir.class_eval %Q[class #{klass} < #{super_class}; end]
        end

        unless Watir.const_defined? "#{klass}Collection"
          Watir.class_eval %Q[class #{klass}Collection < #{args[:super_collection] || super_class}Collection; end]
        end

        tag_name = args[:tag_name] || method_name

        Watir::Container.module_eval %Q[
          def #{method_name}(how={}, what=nil)
            #{klass}.new(self, format_specifiers(#{tag_name.inspect}, how, what))
          end

          def #{args.delete(:plural) || method_name.to_s + "s"}(how={}, what=nil)
            specifiers = format_specifiers(#{tag_name.inspect}, how, what)
            #{klass}Collection.new(self, specifiers)
          end
        ]
      end

    end

    support_element :a, :class => :Link
    alias_method :link, :a
    alias_method :links, :as
    support_element :abbr
    support_element :address, :plural => :addresses
    support_element :area
    support_element :article
    support_element :aside
    support_element :audio
    support_element :b
    support_element :base
    support_element :bdi
    support_element :bdo
    support_element :blockquote
    support_element :body
    support_element :br
    support_element :button, :tag_name => [:button, :submit, :image, :reset], :super_class => :InputElement
    support_element :canvas, :plural => :canvases 
    support_element :caption
    support_element :checkbox, :plural => :checkboxes, :class => :CheckBox, :super_class => :InputElement
    support_element :cite
    support_element :code
    support_element :col
    support_element :colgroup
    support_element :command
    support_element :data
    support_element :datalist
    support_element :dd
    support_element :del
    support_element :details, :plural => :detailses
    support_element :dfn
    support_element :div
    support_element :dl
    support_element :dt
    support_element :element, :tag_name => "*", :class => :HTMLElement
    support_element :em
    support_element :embed
    support_element :fieldset, :class => :FieldSet
    alias_method :field_set, :fieldset
    alias_method :field_sets, :fieldsets
    support_element :figcaption
    support_element :figure
    support_element :file_field, :tag_name => :file, :class => :FileField, :super_collection => :InputElement
    support_element :font
    support_element :footer
    support_element :form
    support_element :frame, :tag_name => [:frame, :iframe]
    alias_method :iframe, :frame
    alias_method :iframes, :frames
    support_element :frameset
    support_element :h1
    support_element :h2
    support_element :h3
    support_element :h4
    support_element :h5
    support_element :h6
    support_element :head
    support_element :header
    support_element :hgroup
    support_element :hidden, :super_class => :TextField, :super_collection => :InputElement
    support_element :hr
    support_element :i
    support_element :img, :class => :Image
    alias_method :image, :img
    alias_method :images, :imgs
    support_element :input, :super_class => :InputElement
    support_element :ins, :plural => :inses
    support_element :kbd
    support_element :keygen
    support_element :label
    support_element :legend
    support_element :li
    support_element :map
    support_element :mark
    support_element :menu
    support_element :meta
    support_element :meter
    support_element :nav
    support_element :noscript
    support_element :object
    support_element :ol
    support_element :optgroup
    support_element :option
    support_element :output
    support_element :p
    support_element :param
    support_element :pre
    support_element :progress, :plural => :progresses
    support_element :q
    support_element :radio, :super_class => :InputElement
    support_element :rp
    support_element :rt
    support_element :ruby, :plural => :rubies
    support_element :s
    support_element :samp
    support_element :script
    support_element :section
    support_element :select, :class => :SelectList, :super_class => :InputElement
    alias_method :select_list, :select
    alias_method :select_lists, :selects
    support_element :small
    support_element :source
    support_element :span
    support_element :strong
    support_element :style
    support_element :sub
    support_element :summary, :plural => :summaries
    support_element :sup
    support_element :table
    support_element :tbody, :class => :TableSection
    support_element :td, :tag_name => [:th, :td], :class => :TableCell
    support_element :text_field, :tag_name => [:text, :password, :textarea, :number, :email, :url, :search, :tel], :class => :TextField, :super_class => :InputElement
    support_element :textarea, :class => :TextArea, :super_class => :TextField, :super_collection => :InputElement
    support_element :tfoot, :class => :TableSection
    support_element :th
    support_element :thead, :class => :TableSection
    support_element :time
    support_element :title
    support_element :tr, :class => :TableRow
    support_element :track
    support_element :u
    support_element :ul
    support_element :var
    support_element :video
    support_element :wbr

    private

    def format_specifiers(tag_name, how, what)
      defaults = {:tag_name => [tag_name].flatten.map(&:to_s)}
      formatted_specifiers = defaults.merge(what ? {how => what} : how)
      if (formatted_specifiers[:css] || formatted_specifiers[:xpath]) && formatted_specifiers.size > 2
        raise ArgumentError, ":xpath and :css specifiers should be the only one when used in #{formatted_specifiers.inspect}"
      end
      formatted_specifiers
    end

  end
end
