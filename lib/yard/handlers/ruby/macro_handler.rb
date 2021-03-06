module YARD
  module Handlers
    module Ruby
      # Handles a macro (dsl-style method)
      class MacroHandler < Base
        include CodeObjects
        include MacroHandlerMethods
        handles method_call
        namespace_only
        
        IGNORE_METHODS = Hash[*%w(alias alias_method autoload attr attr_accessor 
          attr_reader attr_writer extend include public private protected 
          private_constant).map {|n| [n, true] }.flatten]
        
        process do
          return if namespace == Registry.root
          globals.__attached_macros ||= {}
          if !globals.__attached_macros[caller_method]
            return if IGNORE_METHODS[caller_method]
            return if !statement.comments || statement.comments.empty?
          end
          
          @macro, @docstring = nil, Docstring.new(statement.comments)
          find_or_create_macro
          return if !@macro && !statement.comments_hash_flag && @docstring.tags.size == 0
          @docstring = expanded_macro_or_docstring
          @docstring.hash_flag = statement.comments_hash_flag
          @docstring.line_range = statement.comments_range
          name = method_name
          raise UndocumentableError, "method, missing name" if name.nil? || name.empty?
          tmp_scope = sanitize_scope
          tmp_vis = sanitize_visibility
          object = MethodObject.new(namespace, name, tmp_scope)
          register(object)
          object.visibility = tmp_vis
          object.dynamic = true
          object.docstring = @docstring
          object.signature = method_signature
          create_attribute_data(object)
        end

        private

        def call_params
          return [] unless statement.respond_to?(:parameters)
          statement.parameters(false).map do |param|
            param.jump(:ident, :tstring_content).source
          end
        end

        def caller_method
          if statement.call?
            statement.method_name(true).to_s
          else
            statement[0].jump(:ident).source
          end
        end
      end
    end
  end
end
