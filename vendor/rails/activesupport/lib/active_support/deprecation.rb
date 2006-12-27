require 'yaml'

module ActiveSupport
  module Deprecation
    mattr_accessor :debug
    self.debug = false

    # Choose the default warn behavior according to RAILS_ENV.
    # Ignore deprecation warnings in production.
    DEFAULT_BEHAVIORS = {
      'test'        => Proc.new { |message, callstack|
                         $stderr.puts(message)
                         $stderr.puts callstack.join("\n  ") if debug
                       },
      'development' => Proc.new { |message, callstack|
                         RAILS_DEFAULT_LOGGER.warn message
                         RAILS_DEFAULT_LOGGER.debug callstack.join("\n  ") if debug
                       }
    }

    class << self
      def warn(message = nil, callstack = caller)
        behavior.call(deprecation_message(callstack, message), callstack) if behavior && !silenced?
      end

      def default_behavior
        if defined?(RAILS_ENV)
          DEFAULT_BEHAVIORS[RAILS_ENV.to_s]
        else
          DEFAULT_BEHAVIORS['test']
        end
      end

      # Have deprecations been silenced?
      def silenced?
        @silenced = false unless defined?(@silenced)
        @silenced
      end

      # Silence deprecations for the duration of the provided block. For internal
      # use only.
      def silence
        old_silenced, @silenced = @silenced, true # We could have done behavior = nil...
        yield
      ensure
        @silenced = old_silenced
      end

      attr_writer :silenced


      private
        def deprecation_message(callstack, message = nil)
          file, line, method = extract_callstack(callstack)
          message ||= "You are using deprecated behavior which will be removed from Rails 2.0."
          "DEPRECATION WARNING: #{message}  See http://www.rubyonrails.org/deprecation for details. (called from #{method} at #{file}:#{line})"
        end

        def extract_callstack(callstack)
          callstack.first.match(/^(.+?):(\d+)(?::in `(.*?)')?/).captures
        end
    end

    # Behavior is a block that takes a message argument.
    mattr_accessor :behavior
    self.behavior = default_behavior

    # Warnings are not silenced by default.
    self.silenced = false

    module ClassMethods
      # Declare that a method has been deprecated.
      def deprecate(*method_names)
        options = method_names.last.is_a?(Hash) ? method_names.pop : {}
        method_names = method_names + options.keys
        method_names.each do |method_name|
          alias_method_chain(method_name, :deprecation) do |target, punctuation|
            class_eval(<<-EOS, __FILE__, __LINE__)
              def #{target}_with_deprecation#{punctuation}(*args, &block)
                ::ActiveSupport::Deprecation.warn(self.class.deprecated_method_warning(:#{method_name}, #{options[method_name].inspect}), caller)
                #{target}_without_deprecation#{punctuation}(*args, &block)
              end
            EOS
          end
        end
      end

      def deprecated_method_warning(method_name, message=nil)
        warning = "#{method_name} is deprecated and will be removed from Rails #{deprecation_horizon}"
        case message
          when Symbol then "#{warning} (use #{message} instead)"
          when String then "#{warning} (#{message})"
          else warning
        end
      end

      def deprecation_horizon
        '2.0'
      end
    end

    module Assertions
      def assert_deprecated(match = nil, &block)
        result, warnings = collect_deprecations(&block)
        assert !warnings.empty?, "Expected a deprecation warning within the block but received none"
        if match
          match = Regexp.new(Regexp.escape(match)) unless match.is_a?(Regexp)
          assert warnings.any? { |w| w =~ match }, "No deprecation warning matched #{match}: #{warnings.join(', ')}"
        end
        result
      end

      def assert_not_deprecated(&block)
        result, deprecations = collect_deprecations(&block)
        assert deprecations.empty?, "Expected no deprecation warning within the block but received #{deprecations.size}: \n  #{deprecations * "\n  "}"
        result
      end

      private
        def collect_deprecations
          old_behavior = ActiveSupport::Deprecation.behavior
          deprecations = []
          ActiveSupport::Deprecation.behavior = Proc.new do |message, callstack|
            deprecations << message
          end
          result = yield
          [result, deprecations]
        ensure
          ActiveSupport::Deprecation.behavior = old_behavior
        end
    end

    # Stand-in for @request, @attributes, etc.
    class DeprecatedInstanceVariableProxy
      instance_methods.each { |m| undef_method m unless m =~ /^__/ }

      def initialize(instance, method, var = "@#{method}")
        @instance, @method, @var = instance, method, var
      end

      private
        def warn(callstack, called, args)
          ActiveSupport::Deprecation.warn("#{@var} is deprecated! Call #{@method}.#{called} instead of #{@var}.#{called}. Args: #{args.inspect}", callstack)
        end

        def method_missing(called, *args, &block)
          warn caller, called, args
          @instance.__send__(@method).__send__(called, *args, &block)
        end
    end
  end
end

class Module
  include ActiveSupport::Deprecation::ClassMethods
end

module Test
  module Unit
    class TestCase
      include ActiveSupport::Deprecation::Assertions
    end
  end
end
