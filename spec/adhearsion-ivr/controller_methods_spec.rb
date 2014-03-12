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

    context "when the call is dead" do
      before { call.terminate }

      it "executing the controller should raise Adhearsion::Call::Hangup" do
        expect { subject.run }.to raise_error Adhearsion::Call::Hangup
      end
    end
  end
end
