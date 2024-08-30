# frozen_string_literal: true

require "irb"

require_relative "helper"

module TestIRB
  class SourceFinderTest < TestCase
    def setup
      IRB.init_config(nil)
      IRB.conf[:USE_SINGLELINE] = false
      IRB.conf[:VERBOSE] = false
      IRB.conf[:USE_PAGER] = false
      workspace = IRB::WorkSpace.new(Object.new)
      @context = IRB::Context.new(nil, workspace)

      @get_screen_size = Reline.method(:get_screen_size)
      Reline.instance_eval { undef :get_screen_size }
      def Reline.get_screen_size
        [36, 80]
      end
      save_encodings

      @source_finder = IRB::SourceFinder.new(@context)
    end

    def teardown
      Reline.instance_eval { undef :get_screen_size }
      Reline.define_singleton_method(:get_screen_size, @get_screen_size)
      restore_encodings
    end

    def test_resolve_rdoc_path_for_constant
      assert_equal "String.html", @source_finder.resolve_rdoc_path("String")
      assert_equal "String.html", @source_finder.resolve_rdoc_path("::String")
      assert_equal "IRB/Context.html", @source_finder.resolve_rdoc_path("IRB::Context")
    end

    def test_resolve_rdoc_path_for_instance_method
      assert_equal "String.html#method-i-upcase", @source_finder.resolve_rdoc_path("String#upcase")
    end

    def test_resolve_rdoc_path_for_class_method
      assert_equal "String.html#method-c-new", @source_finder.resolve_rdoc_path("String.new")
    end

    def test_resolve_rdoc_path_for_nonexistent_constant
      assert_nil @source_finder.resolve_rdoc_path("NonexistentConstant")
    end

    def test_resolve_rdoc_path_for_nonexistent_method
      assert_nil @source_finder.resolve_rdoc_path("String#nonexistent_method")
    end
  end
end
