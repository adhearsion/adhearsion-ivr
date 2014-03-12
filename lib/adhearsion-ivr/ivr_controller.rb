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
      @@prompts = []
      def prompts
        @@prompts
      end

      # maximum number of attempts to prompt the caller for input
      @@max_attempts = 3
      def max_attempts(num)
        @@max_attempts = num
      end

      # called when the caller successfully provides input
      def on_complete(&block)
        @@completion_callback = block
      end

      # Called when the caller errors more than the number of allowed attempts
      def on_failure(&block)
        @@failure_callback = block
      end
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
      prompt = @@prompts[@errors] || @@prompts.last
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
    end

    def grammar
      raise "You must override this method and provide a grammar"
    end

    def increment_errors
      @errors += 1
    end

    def continue?
      @errors < @@max_attempts
    end

    def completion_callback
      instance_exec @result, &@@completion_callback
    end

    def failure_callback
      instance_exec &@@failure_callback
    end
  end
end
