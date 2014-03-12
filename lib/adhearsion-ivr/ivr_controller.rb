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

      # maximum number of attempts to prompt the caller for input
      def max_attempts(num = nil)
        if num
          @max_attempts = num
        else
          @max_attempts || 3
        end
      end

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
      event(:match)    { transition prompting: :complete }
      event(:reprompt) { transition input_error: :prompting }
      event(:nomatch)  { transition prompting: :input_error }
      event(:no_input) { transition prompting: :input_error }
      event(:failure)  { transition prompting: :failure, input_error: :failure }

      after_transition :prompting => :input_error do |controller|
        controller.increment_errors
        if controller.continue?
          controller.reprompt!
        else
          controller.failure!
        end
      end

      after_transition any => :prompting do |controller|
        controller.deliver_prompt
      end

      after_transition :prompting => :complete do |controller|
        controller.completion_callback
      end

      after_transition any => :failure do |controller|
        controller.failure_callback
      end
    end

    def run
      @errors = 0
      deliver_prompt
    end

    def deliver_prompt
      prompt = self.class.prompts[@errors] || self.class.prompts.last
      prompt = instance_exec(&prompt) if prompt.respond_to? :call
      logger.debug "Prompt: #{prompt.inspect}"

      @result = ask prompt, grammar: grammar, mode: :voice
      logger.debug "Got result #{@result.inspect}"
      case @result.status
      when :match
        match!
      when :stop
        logger.info "Prompt was stopped forcibly. Exiting cleanly..."
      when :hangup
        logger.info "Call was hung up mid-prompt. Exiting controller flow..."
        raise Adhearsion::Call::Hangup
      else
        nomatch!
      end
      @result
    end

    def grammar
      raise NotImplementedError, "You must override #grammar and provide a grammar"
    end

    def increment_errors
      @errors += 1
    end

    def continue?
      @errors < self.class.max_attempts
    end

    def completion_callback
      instance_exec @result, &self.class.completion_callback if self.class.completion_callback
    end

    def failure_callback
      instance_exec &self.class.failure_callback
    end
  end
end
