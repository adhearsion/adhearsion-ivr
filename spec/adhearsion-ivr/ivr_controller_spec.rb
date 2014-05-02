# encoding: utf-8

require 'spec_helper'

describe Adhearsion::IVRController do
  describe "when we inherit from it" do

    let(:call_id)     { SecureRandom.uuid }
    let(:call)        { Adhearsion::Call.new }

    let(:controller_class) do
      expected_prompts = self.expected_prompts
      apology_announcement = self.apology_announcement

      Class.new(Adhearsion::IVRController) do
        expected_prompts.each do |prompt|
          prompts << prompt
        end

        on_complete do |result|
          say "Let's go to #{result.utterance}"
        end

        on_failure do
          say apology_announcement
        end

        def grammar
          :some_grammar
        end
      end
    end

    subject(:controller) { controller_class.new call }

    before do
      double call, write_command: true, id: call_id

      Adhearsion::Plugin.configure_plugins if Adhearsion::Plugin.respond_to?(:configure_plugins)
      Adhearsion::Plugin.init_plugins
    end

    let(:expected_prompts) { [SecureRandom.uuid, SecureRandom.uuid, SecureRandom.uuid] }
    let(:apology_announcement) { "Sorry, I couldn't understand where you would like to go. I'll put you through to a human." }

    let(:expected_grammar) { :some_grammar }

    let(:nlsml) do
      RubySpeech::NLSML.draw do
        interpretation confidence: 1 do
          input 'Paris', mode: :voice
          instance 'Paris'
        end
      end
    end

    let(:match_result) do
      AdhearsionASR::Result.new.tap do |res|
        res.status         = :match
        res.mode           = :voice
        res.confidence     = 1
        res.utterance      = 'Paris'
        res.interpretation = 'Paris'
        res.nlsml          = nlsml
      end
    end

    let(:noinput_result) do
      AdhearsionASR::Result.new.tap do |res|
        res.status = :noinput
      end
    end

    context "when an utterance is received" do
      before do
        controller.should_receive(:ask).once.with(expected_prompts[0], grammar: expected_grammar, mode: :voice).and_return result
      end

      context "that is a match" do
        let(:result) { match_result }

        it "passes the Result object to the on_complete block" do
          controller.should_receive(:say).once.with "Let's go to Paris"
          controller.run
        end
      end

      context "that is a noinput" do
        let(:result) { noinput_result }

        context "followed by a match" do
          before do
            controller.should_receive(:ask).once.with(expected_prompts[1], grammar: expected_grammar, mode: :voice).and_return match_result
          end

          it "re-prompts using the next prompt, and then passes the second Result to the on_complete block" do
            controller.should_receive(:say).once.with "Let's go to Paris"
            controller.run
          end
        end

        context "when there are not enough prompts available for all retries" do
          let(:expected_prompts) { [SecureRandom.uuid, SecureRandom.uuid] }

          before do
            controller.should_receive(:ask).once.with(expected_prompts[1], grammar: expected_grammar, mode: :voice).and_return result
            controller.should_receive(:ask).once.with(expected_prompts[1], grammar: expected_grammar, mode: :voice).and_return match_result
          end

          it "reuses the last prompt" do
            controller.should_receive(:say).once.with "Let's go to Paris"
            controller.run
          end
        end

        context "until it hits the maximum number of attempts" do
          context "using the default of 3 attempts" do
            before do
              controller.should_receive(:ask).once.with(expected_prompts[1], grammar: expected_grammar, mode: :voice).and_return result
              controller.should_receive(:ask).once.with(expected_prompts[2], grammar: expected_grammar, mode: :voice).and_return result
            end

            it "invokes the on_failure block" do
              controller.should_receive(:say).once.with apology_announcement
              controller.run
            end
          end

          context "when that value is different from the default" do
            let(:controller_class) do
              expected_prompts = self.expected_prompts
              apology_announcement = self.apology_announcement

              Class.new(Adhearsion::IVRController) do
                expected_prompts.each do |prompt|
                  prompts << prompt
                end

                max_attempts 2

                on_complete do |result|
                  say "Let's go to #{result.utterance}"
                end

                on_failure do
                  say apology_announcement
                end

                def grammar
                  :some_grammar
                end
              end
            end

            before do
              controller.should_receive(:ask).once.with(expected_prompts[1], grammar: expected_grammar, mode: :voice).and_return result
            end

            it "invokes the on_failure block" do
              controller.should_receive(:say).once.with apology_announcement
              controller.run
            end
          end
        end
      end

      context "that is a nomatch" do
        let(:result) do
          AdhearsionASR::Result.new.tap do |res|
            res.status = :nomatch
          end
        end

        context "followed by a match" do
          before do
            controller.should_receive(:ask).once.with(expected_prompts[1], grammar: expected_grammar, mode: :voice).and_return match_result
          end

          it "re-prompts using the next prompt, and then passes the second Result to the on_complete block" do
            controller.should_receive(:say).once.with "Let's go to Paris"
            controller.run
          end
        end

        context "when there are not enough prompts available for all retries" do
          let(:expected_prompts) { [SecureRandom.uuid, SecureRandom.uuid] }

          before do
            controller.should_receive(:ask).once.with(expected_prompts[1], grammar: expected_grammar, mode: :voice).and_return result
            controller.should_receive(:ask).once.with(expected_prompts[1], grammar: expected_grammar, mode: :voice).and_return match_result
          end

          it "reuses the last prompt" do
            controller.should_receive(:say).once.with "Let's go to Paris"
            controller.run
          end
        end

        context "until it hits the maximum number of attempts" do
          context "using the default of 3 attempts" do
            before do
              controller.should_receive(:ask).once.with(expected_prompts[1], grammar: expected_grammar, mode: :voice).and_return result
              controller.should_receive(:ask).once.with(expected_prompts[2], grammar: expected_grammar, mode: :voice).and_return result
            end

            it "invokes the on_failure block" do
              controller.should_receive(:say).once.with apology_announcement
              controller.run
            end
          end

          context "when that value is different from the default" do
            let(:controller_class) do
              expected_prompts = self.expected_prompts
              apology_announcement = self.apology_announcement

              Class.new(Adhearsion::IVRController) do
                expected_prompts.each do |prompt|
                  prompts << prompt
                end

                max_attempts 2

                on_complete do |result|
                  say "Let's go to #{result.utterance}"
                end

                on_failure do
                  say apology_announcement
                end

                def grammar
                  :some_grammar
                end
              end
            end

            before do
              controller.should_receive(:ask).once.with(expected_prompts[1], grammar: expected_grammar, mode: :voice).and_return result
            end

            it "invokes the on_failure block" do
              controller.should_receive(:say).once.with apology_announcement
              controller.run
            end
          end
        end
      end

      context "that is a hangup" do
        let(:controller_class) do
          expected_prompts = self.expected_prompts

          Class.new(Adhearsion::IVRController) do
            expected_prompts.each do |prompt|
              prompts << prompt
            end

            on_complete do |result|
              raise "Got complete"
            end

            on_failure do
              raise "Got failure"
            end

            def grammar
              :some_grammar
            end
          end
        end

        let(:result) do
          AdhearsionASR::Result.new.tap do |res|
            res.status = :hangup
          end
        end

        it "raises Adhearsion::Call::Hangup" do
          expect { controller.run }.to raise_error(Adhearsion::Call::Hangup)
        end
      end

      context "that is a stop" do
        let(:controller_class) do
          expected_prompts = self.expected_prompts

          Class.new(Adhearsion::IVRController) do
            expected_prompts.each do |prompt|
              prompts << prompt
            end

            on_complete do |result|
              raise "Got complete"
            end

            on_failure do
              raise "Got failure"
            end

            def grammar
              :some_grammar
            end
          end
        end

        let(:result) do
          AdhearsionASR::Result.new.tap do |res|
            res.status = :stop
          end
        end

        it "falls through silently" do
          controller.run
        end
      end
    end

    context "when the prompts are callable" do
      let(:controller_class) do
        Class.new(Adhearsion::IVRController) do
          prompts << -> { thing }

          on_complete do |result|
          end

          on_failure do
          end

          def grammar
            :some_grammar
          end

          def thing
            @things ||= %w{one two three}
            @things.shift
          end
        end
      end

      it "should evaluate the prompt repeatedly in the context of the controller instance" do
        controller.should_receive(:ask).once.with('one', grammar: expected_grammar, mode: :voice).and_return noinput_result
        controller.should_receive(:ask).once.with('two', grammar: expected_grammar, mode: :voice).and_return noinput_result
        controller.should_receive(:ask).once.with('three', grammar: expected_grammar, mode: :voice).and_return noinput_result
        controller.run
      end
    end

    context "when no grammar is provided" do
      let(:controller_class) do
        Class.new(Adhearsion::IVRController) do
          prompts << "Hello"

          on_complete do |result|
          end

          on_failure do
          end
        end
      end

      it "should raise NotImplementedError" do
        expect { controller.run }.to raise_error(NotImplementedError)
      end
    end

    context "when no complete callback is provided" do
      let(:controller_class) do
        Class.new(Adhearsion::IVRController) do
          prompts << "Hello"

          def grammar
            :some_grammar
          end
        end
      end

      it "should simply return the result" do
        controller.should_receive(:ask).once.with('Hello', grammar: expected_grammar, mode: :voice).and_return match_result
        controller.run.should be(match_result)
      end
    end

    context "when no complete callback is provided" do
      let(:controller_class) do
        Class.new(Adhearsion::IVRController) do
          prompts << "Hello"

          def grammar
            :some_grammar
          end
        end
      end

      it "should simply return the last result" do
        controller.should_receive(:ask).once.with('Hello', grammar: expected_grammar, mode: :voice).and_return noinput_result
        controller.should_receive(:ask).once.with('Hello', grammar: expected_grammar, mode: :voice).and_return noinput_result
        controller.should_receive(:ask).once.with('Hello', grammar: expected_grammar, mode: :voice).and_return noinput_result
        controller.run.should be(noinput_result)
      end
    end

    context "when the call is dead" do
      before { call.terminate }

      it "executing the controller should raise Adhearsion::Call::Hangup" do
        expect { subject.run }.to raise_error Adhearsion::Call::Hangup
      end
    end

    context "when overriding prompts" do
      let(:override_prompts) { [SecureRandom.uuid, SecureRandom.uuid, SecureRandom.uuid] }

      before do
        override_prompts = self.override_prompts
        controller_class.send :define_method, :prompts do
          override_prompts
        end
      end

      context "with a successful match" do
        let(:result) { match_result }

        it "plays the correct prompt" do
          controller.should_receive(:ask).once.with(override_prompts[0], grammar: expected_grammar, mode: :voice).and_return result
          controller.should_receive(:say).once.with "Let's go to Paris"
          controller.run
        end
      end
    end
  end
end
