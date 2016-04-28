module ActionMailer
  module Markdown
    module TemplateHandler
      UNDERSCORE = "_".freeze
      OBJECT_ATTRIBUTE_MATCHER = /%\{([a-z0-9_]+\.[a-z0-9_]+)\}/i

      def self.render(template, context, format)
        variables = expand_variables(template, extract_variables(context))
        source = template.rstrip % variables
        ActionMailer::Markdown.public_send(format, source)
      end

      def self.expand_variables(template, variables)
        template.scan(OBJECT_ATTRIBUTE_MATCHER)
          .map(&:first)
          .each_with_object(variables) do |match, buffer|
            target, attribute = match.split(".")
            buffer[match.to_sym] = variables[target.to_sym].public_send(attribute)
          end
      end

      def self.extract_variables(context)
        context
          .instance_variable_get(:@_assigns)
          .each_with_object({}) do |(name, value), buffer|
            next if name.start_with?(UNDERSCORE)
            buffer[name.to_sym] = value
          end
      end

      class Text
        def self.call(template)
          %[
            ActionMailer::Markdown::TemplateHandler
              .render(#{template.source.inspect}, self, :text)
          ]
        end
      end

      class HTML
        def self.call(template)
          %[
            ActionMailer::Markdown::TemplateHandler
              .render(#{template.source.inspect}, self, :html)
          ]
        end
      end
    end
  end
end
