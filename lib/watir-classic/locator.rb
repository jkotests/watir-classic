module Watir
  # @private
  class Locator
    include Watir
    include Watir::Exception
    include XpathLocator

    def initialize container, specifiers, klass
      @container = container
      @specifiers = {:index => 0}.merge(normalize_specifiers(specifiers))
      @tags = [@specifiers.delete(:tag_name)].flatten
      @klass = klass
    end

    def each
      if has_excluding_specifiers?
        locate_elements_by_xpath_css_ole.each do |element|
          yield create_element element
        end
      else
        @tags.each do |tag|
          each_element(tag) do |element| 
            next unless type_matches?(element.ole_object) && match_with_specifiers?(element)
            yield element          
          end 
        end
      end
      nil
    end    

    def document
      @document ||= @container.document
    end

    def normalize_specifiers(specifiers)
      specifiers.reduce({}) do |memo, pair|
        how, what = *pair
        case how
        when :index
          what = what.to_i
        when :url
          how = :href
        when :class
          how = :class_name
        when :caption
          how = :text
        when :method
          how = :form_method
        when :value
          what = what.is_a?(Regexp) ? what : what.to_s
        end

        memo[how] = what
        memo
      end
    end

    def match_with_specifiers?(element)
      return true if has_excluding_specifiers?
      @specifiers.all? do |how, what|
        how == :index || 
          (how == :class_name && match_class?(element, what)) ||
          match?(element, how, what)
      end
    end

    def match_class? element, what
      classes = element.class_name.split(/\s+/)
      classes.any? {|clazz| what.matches(clazz)}
    end

    # return true if the element matches the provided how and what
    def match? element, how, what
      begin
        attribute = element.send(how)
      rescue NoMethodError
        raise MissingWayOfFindingObjectException,
          "#{how} is an unknown way of finding a <#{@tags.join(", ")}> element (#{what})"
      end

      what.matches(attribute)
    end

    def has_excluding_specifiers?
      @specifiers.keys.any? {|specifier| [:css, :xpath, :ole_object].include? specifier}
    end

    def locate_by_id
      # Searching through all elements returned by __ole_inner_elements
      # is *significantly* slower than IE's getElementById() and
      # getElementsByName() calls when how is :id.  However
      # IE doesn't match Regexps, so first we make sure what is a String.
      # In addition, IE's getElementById() will also return an element
      # where the :name matches, so we will only return the results of
      # getElementById() if the matching element actually HAS a matching
      # :id.

      the_id = @specifiers[:id]
      if the_id && the_id.class == String 
        element = document.getElementById(the_id) rescue nil
        # Return if our fast match really HAS a matching :id
        return element if element && element.invoke('id') == the_id && type_matches?(element) && match_with_specifiers?(create_element element)
      end

      nil
    end

    def locate_elements_by_xpath_css_ole
      els = []

      if @specifiers[:xpath]
        els = elements_by_xpath(@specifiers[:xpath])
      elsif @specifiers[:css]
        els = elements_by_css(@specifiers[:css])
      elsif @specifiers[:ole_object]
        return [@specifiers[:ole_object]]
      end      

      els.select {|element| type_matches?(element) && match_with_specifiers?(create_element element)}
    end

    def type_matches?(el)
      @tags == ["*"] || 
        @tags.include?(el.tagName.downcase) || 
        @tags.include?(el.invoke('type').downcase) rescue false
    end

    def create_element ole_object
      element = @klass.new(@container, @specifiers.merge(:ole_object => ole_object))
      def element.locate; @o; end
      element
    end
  end

  # @private
  class TaggedElementLocator < Locator
    def each_element(tag)
      document.getElementsByTagName(tag).each do |ole_object|
        yield create_element ole_object
      end
    end

    def locate
      el = locate_by_id
      return el if el
      return locate_elements_by_xpath_css_ole[0] if has_excluding_specifiers?

      count = 0
      each do |element|
        return element.ole_object if count == @specifiers[:index]
        count += 1
      end # elements
      nil
    end
  end

  # @private
  class FrameLocator < TaggedElementLocator
    def each_element(tag)
      frames = @container.page_container.document.frames
      i = 0
      document.getElementsByTagName(tag).each do |ole_object|
        frame = create_element ole_object
        frame.document = frames.item(i)
        yield frame
        i += 1
      end
    end

    def locate
      count = 0
      each do |frame|
        return frame.ole_object, frame.document if count == @specifiers[:index]
        count += 1
      end
    end

    def locate_elements_by_xpath_css_ole
      super.map do |frame|
        frame = create_element frame
        each_element(frame.tag_name) do |frame_with_document|
          if frame_with_document == frame
            frame = frame_with_document
            break
          end
        end
        frame
      end
    end
  end

  # @private
  class FormLocator < TaggedElementLocator
    def each_element(tag)
      document.forms.each do |form|
        yield create_element form
      end
    end
  end

  # @private
  class InputElementLocator < Locator
    def each_element
      elements = locate_by_name || @container.__ole_inner_elements
      elements.each do |object|
        yield create_element object
      end
      nil
    end    

    def locate
      el = locate_by_id
      return el if el
      return locate_elements_by_xpath_css_ole[0] if has_excluding_specifiers?

      count = 0
      each do |element|
        return element.ole_object if count == @specifiers[:index]
        count += 1
      end
    end

    def each
      if has_excluding_specifiers?
        locate_elements_by_xpath_css_ole.each do |element|
          yield element
        end
      else
        each_element do |element| 
          next unless type_matches?(element.ole_object) && match_with_specifiers?(element)
          yield element
        end 
      end
      nil
    end    

    private

    def locate_by_name
      the_name = @specifiers[:name]
      if the_name && the_name.class == String
        return document.getElementsByName(the_name) rescue nil
      end      
      nil
    end
  end

end    
