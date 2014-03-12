# encoding: utf-8
require 'state_machine'

module Adhearsion
  class IVRController < Adhearsion::CallController
    class << self
      attr_accessor :error_limit
  
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

      # Called when the caller errors on input, whether a reject or a no-input
      def on_error(&block)
        @@error_callback = block
      end
  
      # Called when the caller errors more than the number of allowed attempts
      def on_failure(&block)
        @@failure_callback = block
      end
    end
  
    attr_accessor :errors
    
    def run
      @errors = 0
      @state = InputState.new self
      deliver_prompt
    end
      
    def deliver_prompt
      prompt = @@prompts[@errors] || @@prompts.last
      prompt = prompt.call if prompt.respond_to? :call
      logger.debug "Prompt: #{prompt.inspect}"
  
      @result = ask prompt, grammar: grammar, mode: :voice
      if @result.match?
        @state.match
      else
        @state.reject # FIXME: handle no-input as well
      end
    end

    def grammar
      raise "You must override this method and provide a grammar"
    end
      
    def increment_errors
      @errors += 1
    end
  
    def completion_callback
      @@completion_callback.call @result
    end
  
    def failure_callback
      @@failure_callback.call
    end
  
    def max_attempts
      @@max_attempts
    end
  
    def continue?
      @errors >= max_attempts
    end
  
    class InputState
      attr_accessor :call_controller
  
      state_machine initial: :prompting do
        event(:match)    { transition prompting: :complete }
        event(:reprompt) { transition input_error: :prompting }
        event(:reject)   { transition prompting: :input_error }
        event(:no_input) { transition prompting: :input_error }
        event(:failure)  { transition prompting: :failure }
  
        after_transition any => :input_error do |state|
          state.call_controller.increment_errors
          if state.call_controller.continue?
            reprompt
          else
            failure
          end
        end
  
        after_transition any => :prompting do |state|
          state.deliver_prompt
        end
  
        after_transition :prompting => :complete do |state|
          state.call_controller.completion_callback
        end
    
        after_transition :prompting => :failure do |state|
          state.call_controller.failure_callback
        end
      end
  
      def initialize(call_controller)
        @call_controller = call_controller
        super()
      end
    end
  end
end
