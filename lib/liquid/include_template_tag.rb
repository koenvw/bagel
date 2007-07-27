module Liquid
  module Bagel

    class IncludeTemplate < Tag

      Syntax = /(#{QuotedFragment}+)/

      def initialize(markup, tokens)
        if markup =~ Syntax
          # Extract template name
          @template_name = $1

          # Extract attributes
          @attributes = {}
          markup.scan(TagAttributes) { |key, value| @attributes[key] = value.sub(/^data\./, '') }
        else
          raise SyntaxError.new("Error in tag 'include_template' - Valid syntax: include_template '[template]'")
        end
        super
      end

      def parse(tokens)
      end

      def render(context)
        # Find generator
        generator = ::Generator.find_by_name(context[@template_name])
        raise "Liquid error: Cannot find template named #{context[@template_name]}" if generator.nil?

        res = ''

        on_liquid_stack(generator.name) do
          # Change the context for this template only
          context.stack do
            # Add this template's assigns to the data drop
            generator.assigns_as_hash(context['data']).each { |k, v| context['data'][k] = v }

            # Add assigns from include_template call
            @attributes.each { |k, v| context['data'][k] = context['data'][v] }

            # Render template
            res = liquid_template(generator, context)
          end
        end

        res
      end

    end

    Template.register_tag('include_template', IncludeTemplate)  

  end
end
