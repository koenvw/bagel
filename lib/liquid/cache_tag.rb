module Liquid
  module Bagel

    class Cache < Block

      Syntax = /(.*?)[,%]/

      def initialize(markup, tokens)
        if markup =~ Syntax
          @raw_cache_name = $1

          # Extract attributes
          @attributes = {}
          markup.scan(TagAttributes) { |key, value| @attributes[key] = value }

          super 
        else
          raise SyntaxError.new("Error in tag 'cache' - Valid syntax: cache [quoted_cache_name]")
        end
      end

      def render(context)
        # Extract cache name
        data = FakeDataObject.new(context['data'])
        cache_name = eval(@raw_cache_name)

        # Get expire option
        options = (@attributes['expire'].nil? ? {} : { :expire => @attributes['expire'].to_i })

        # Let site controller handle some cache stuff
        drop   = context['site_controller']
        output = drop.site_controller.handle_liquid_caching(cache_name, options, binding, drop.params)

        # Return the output
        output
      end
    end

    Template.register_tag('cache', Cache)

  end
end

class FakeDataObject

  def initialize(obj)
    @obj = obj
  end

  def method_missing(method, *args)
    @obj[method.to_s]
  end

end

class SiteControllerDrop < Liquid::Drop

  def initialize(site_controller, params)
    @site_controller = site_controller
    @params          = params
  end

  def site_controller
    @site_controller
  end

  def params
    @params
  end

end
