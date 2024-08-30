# frozen_string_literal: true

require_relative "../source_finder"
require_relative "../pager"
require_relative "../color"

module IRB
  module Command
    class ShowSource < Base
      include RubyArgsExtractor

      category "Context"
      description "Show the source code of a given method, class/module, or constant."

      help_message <<~HELP_MESSAGE
        Usage: show_source [target] [-s]

          -s  Show the super method. You can stack it like `-ss` to show the super of the super, etc.

        Examples:

          show_source Foo
          show_source Foo#bar
          show_source Foo#bar -s
          show_source Foo.baz
          show_source Foo::BAR
      HELP_MESSAGE

      def execute(arg)
        # Accept string literal for backward compatibility
        str = unwrap_string_literal(arg)
        unless str.is_a?(String)
          puts "Error: Expected a string but got #{str.inspect}"
          return
        end

        str, esses = str.split(" -")
        super_level = esses ? esses.count("s") : 0
        source_finder = SourceFinder.new(@irb_context)
        source = source_finder.find_source(str, super_level)
        rdoc_path = source_finder.resolve_rdoc_path(str)

        if source || rdoc_path
          show_source(source, rdoc_path)
        elsif super_level > 0
          puts "Error: Couldn't locate a super definition for #{str}"
        else
          puts "Error: Couldn't locate a definition for #{str}"
        end
        nil
      end

      private

      def show_source(source, rdoc_path)
        # Note:
        # - We use /master because it has better UI from the latest RDoc
        # - The main reason this is experimental is because we can't easily verify if the documentation actually exists.
        #   While RI may be used to display the documentation directly in a pager, it doesn't have a good API to check
        #   if the documentation exists.
        docs_link = "#{bold("[Experimental] View on Ruby docs")}: https://docs.ruby-lang.org/en/master/#{rdoc_path}" if rdoc_path

        content =
          if source
            if source.binary_file?
              <<~CONTENT
                #{docs_link}
                #{bold('Defined in binary file')}: #{source.file}\n\n
              CONTENT
            else
              code = source.colorized_content || 'Source not available'
              <<~CONTENT
                #{docs_link}

                #{bold("From")}: #{source.file}:#{source.line}

                #{code.chomp}

              CONTENT
            end
          else
            docs_link
          end
        Pager.page_content(content) if content
      end

      def bold(str)
        Color.colorize(str, [:BOLD])
      end
    end
  end
end
