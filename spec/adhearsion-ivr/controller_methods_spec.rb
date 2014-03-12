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

    let(:expected_prompts) { ['Where would you like to go?', 'Sorry, where was that?', "I'm sorry, I didn't understand. Which city would you like to fly to?"] }
    let(:apology_announcement) { "Sorry, I couldn't understand where you would like to go. I'll put you through to a human." }

    let(:expected_grammar) { :some_grammar }

    context "when an utterance is received" do
      before do
        controller.should_receive(:ask).once.with(expected_prompts[0], grammar: expected_grammar, mode: :voice).and_return result
      end

      context "that is a match" do
        let :nlsml do
          RubySpeech::NLSML.draw do
            interpretation confidence: 1 do
              input 'Paris', mode: :voice
              instance 'Paris'
            end
          end
        end

        let(:result) do
          AdhearsionASR::Result.new.tap do |res|
            res.status         = :match
            res.mode           = :voice
            res.confidence     = 1
            res.utterance      = 'Paris'
            res.interpretation = 'Paris'
            res.nlsml          = nlsml
          end
        end

        it "passes the Result object to the on_complete block" do
          controller.should_receive(:say).once.with "Let's go to Paris"
          controller.run
        end
      end

      context "that is a noinput" do
        let(:result) do
          AdhearsionASR::Result.new.tap do |res|
            res.status = :noinput
          end
        end

        context "followed by a match" do
          it "re-prompts using the next prompt, and then passes the second Result to the on_complete block"
        end

        context "until it hits the maximum number of attempts" do
          it "invokes the on_failure block"
        end
      end

      context "that is a nomatch" do
        let(:result) do
          AdhearsionASR::Result.new.tap do |res|
            res.status = :nomatch
          end
        end

        context "followed by a match" do
          it "re-prompts using the next prompt, and then passes the second Result to the on_complete block"
        end

        context "until it hits the maximum number of attempts" do
          it "invokes the on_failure block"
        end
      end

      context "that is a hangup" do
        let(:result) do
          AdhearsionASR::Result.new.tap do |res|
            res.status = :hangup
          end
        end

        it "falls through silently"
      end

      context "that is a stop" do
        let(:result) do
          AdhearsionASR::Result.new.tap do |res|
            res.status = :stop
          end
        end

        it "falls through silently"
      end
    end

    context "when the call is dead" do
      before { call.terminate }

      it "executing the controller should raise Adhearsion::Call::Hangup" do
        expect { subject.run }.to raise_error Adhearsion::Call::Hangup
      end
    end
  end
end
