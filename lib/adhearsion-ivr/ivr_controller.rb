# encoding: utf-8

require 'state_machine'
require 'adhearsion-asr'

module Adhearsion
  class IVRController < Adhearsion::CallController
    class << self
      # list of prompts to be played to the caller.
      # this should have one prompt for each attempt
      # in case there are not enough prompts, the final prompt will be re-used until
      # the max_attempts are exceeded.
      def prompts
        @prompts ||= []
      end

      def barge(val = nil)
        if val.nil?
          @barge || false
        else
          @barge = val
        end
      end

      # maximum number of attempts to prompt the caller for input
      def max_attempts(num = nil)
        if num
          @max_attempts = num
        else
          @max_attempts || 3
        end
      end

      # timeout in seconds for each menu attempt
      def timeout(num = nil)
        if num
          @timeout = num
        else
          @timeout || nil
        end
      end

      # renderer to use for the prompts
      def renderer(engine = nil)
        if engine
          @renderer = engine
        else
          @renderer || nil
        end
      end

      # input options to use for the prompts
      def input_options(input_options = nil)
        if input_options
          @input_options = input_options
        else
          @input_options || nil
        end
      end

      # output options to use for the prompts
      def output_options(output_options = nil)
        if output_options
          @output_options = output_options
        else
          @output_options || nil
        end
      end

      # called to verify matched input is valid - should be truthy for valid input, falsey otherwise.
      def validate_input(&block)
        @validate_callback = block
      end
      attr_reader :validate_callback

      # called when the caller successfully provides input
      def on_complete(&block)
        @completion_callback = block
      end
      attr_reader :completion_callback

      # Called when the caller errors more than the number of allowed attempts
      def on_failure(&block)
        @failure_callback = block
      end
      attr_reader :failure_callback
    end

    state_machine initial: :prompting do
      event(:match)    { transition prompting: :validation }
      event(:valid)    { transition validation: :complete }
      event(:invalid)  { transition validation: :input_error }
      event(:reprompt) { transition input_error: :prompting }
      event(:nomatch)  { transition prompting: :input_error }
      event(:noinput)  { transition prompting: :input_error }
      event(:failure)  { transition prompting: :failure, input_error: :failure }

      after_transition any => :input_error do |controller|
        controller.increment_errors
        if controller.continue?
          controller.reprompt!
        else
          controller.failure!
        end
      end

      after_transition any => :validation do |controller|
        if controller.validate_callback
          controller.valid!
        else
          controller.invalid!
        end
      end

      after_transition any => :prompting do |controller|
        controller.deliver_prompt
      end

      after_transition any => :complete do |controller|
        controller.completion_callback
      end

      after_transition any => :failure do |controller|
        controller.failure_callback
      end
    end

    def run
      @errors = 0
      deliver_prompt interruptible: true
    end

    def deliver_prompt(interruptible: nil)
      prompt = prompts[@errors] || prompts.last
      prompt = instance_exec(&prompt) if prompt.respond_to? :call
      logger.debug "Prompt: #{prompt.inspect}"

      if interruptible.nil?
        interruptible = self.barge
        @barge = nil
      end

      if grammar
        ask_options = { grammar: grammar, mode: :voice }
      elsif grammar_url
        ask_options = { grammar_url: grammar_url, mode: :voice }
      else
        fail NotImplementedError, 'You must override #grammar or #grammar_url and provide an input grammar'
      end

      ask_options[:interruptible] = interruptible
      ask_options[:timeout] = timeout if timeout

      if output_options && renderer
        ask_options[:output_options] = output_options.merge({ renderer: renderer })
      elsif output_options
        ask_options[:output_options] = output_options
      elsif renderer
        ask_options[:output_options] = { renderer: renderer }
      end

      ask_options[:input_options] = input_options if input_options

      @result = ask prompt, ask_options
      logger.debug "Got result #{@result.inspect}"
      case @result.status
      when :match
        match!
      when :stop
        logger.info "Prompt was stopped forcibly. Exiting cleanly..."
      when :hangup
        logger.info "Call was hung up mid-prompt. Exiting controller flow..."
        fail Adhearsion::Call::Hangup
      when :nomatch
        nomatch!
      when :noinput
        noinput!
      else
        fail "Unrecognized result status: #{@result.status}"
      end
      @result
    end

    def grammar
      nil
    end

    def grammar_url
      nil
    end

    def prompts
      self.class.prompts
    end

    def barge(val = nil)
      if val.nil?
        @barge.nil? ? self.class.barge : @barge
      else
        @barge = val
      end
    end

    def max_attempts
      self.class.max_attempts
    end

    def timeout
      self.class.timeout
    end

    def renderer
      self.class.renderer
    end

    def input_options
      self.class.input_options
    end

    def output_options
      self.class.output_options
    end

    def increment_errors
      @errors += 1
    end

    def continue?
      @errors < max_attempts
    end

    def validate_callback
      if self.class.validate_callback
        instance_exec &self.class.validate_callback
      else
        true
      end
    end

    def completion_callback
      instance_exec @result, &self.class.completion_callback if self.class.completion_callback
    end

    def failure_callback
      instance_exec &self.class.failure_callback if self.class.failure_callback
    end
  end
end
