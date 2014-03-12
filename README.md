adhearsion-ivr
===============

IVR building blocks for Adhearsion apps

## Installing

Simply add to your Gemfile like any other Adhearsion plugin:

```Ruby
gem 'adhearsion-ivr'
```

## Configuration

Adhearsion IVR currently has no configurable options.

## Examples

A bare-bones example of creating a prompt. This menu has a single message, "Please enter a number 1 through 3."  By default, the caller has 3 attempts to enter any of 1, 2 or 3 (though the actual grammar is left as an exercise to the developer).  If 1 is pressed, the caller is sent to the OneController; if 2 is pressed the caller is sent to the TwoController; if 3 is pressed the caller hears a poor impersonation of the Three Stooges and is hung up.

If the caller fails to provde input within 3 attempts, he hears a taunting message and is then transferred to a waiting kindergarten teacher.

```Ruby
class SimplePrompt < InputController
  prompts << "Please enter a number 1 through 3"
  grammar = one_through_five_grammar
  
  on_complete do |result|
    case result.nlsml.interpretations.first[:instance] # FIXME?
    when 1
      pass OneController
    when 2
      pass TwoController
    when 3
      say "Yuk yuk yuk"
      hangup
    end
  end
  
  on_failure do
    say "Sorry you failed kindergarten. Let us transfer you to our trained staff of kindergarten teachers."
    dial 'sip:kindergarten_teachers@elementaryschool.com'
  end
  
  def one_through_five_grammar
    RubySpeech::GRXML.draw do
      # ... pretend I put a valid GRXML grammar here
    end
  end
end
```

An example with escalating prompts:

```Ruby
class EscalatedPrompt < InputController
  prompts << "First attempt: enter a number"
  prompts << "Second attempt: enter a number 1 through 3"
  prompts << "Third attempt: enter a number 1 through 3. That would be the top row of your DTMF keypad. Don't get it wrong again."
  prompts << "Fourth attempt: really? Was I not clear the first 3 times? Last chance, dunce."
  
  max_attempts 4
 
  on_complete do |result|
    case result.nlsml.interpretations.first[:instance] # FIXME?
    when 1
      pass OneController
    when 2
      pass TwoController
    when 3
      say "Yuk yuk yuk"
      hangup
    end
  end
  
  on_failure do
    say "Sorry you failed kindergarten. Let us transfer you to our trained staff of kindergarten teachers."
    dial 'sip:kindergarten_teachers@elementaryschool.com'
  end
  
  def grammar
    RubySpeech::GRXML.draw do
      # ... pretend I put a valid GRXML grammar here
    end
  end
end
```

A slightly more involved example showing integration with I18n:

```Ruby
class I18nEscalatedPrompts < InputController
  # Note that by deferring prompt resolution we can take advantage of per-call variables such as language selection
  prompts << -> { t(:first_attempt) }
  prompts << -> { t(:second_attempt) }
  prompts << -> { t(:third_attempt) }
  prompts << -> { [ t(:fourth_attempt), t(:this_is_your_final_attempt) ] }
  # Future improvement: we could potentially also include the previous input
  # in the re-prompts, but that isn't implemented now
  
  max_attempts 4
 
  on_complete do |result|
    case result.nlsml.interpretations.first[:instance] # FIXME?
    when 1
      pass OneController
    when 2
      pass TwoController
    when 3
      say "Yuk yuk yuk"
      hangup
    end
  end
  
  on_failure do
    say "Sorry you failed kindergarten. Let us transfer you to our trained staff of kindergarten teachers."
    dial 'sip:kindergarten_teachers@elementaryschool.com'
  end
  
  def grammar
    RubySpeech::GRXML.draw do
      # ... put a valid GRXML grammar here
    end
  end
end
```

## Credits

Copyright (C) 2014 The Adhearsion Foundation

adhearsion-ivr is released under the [MIT license](http://opensource.org/licenses/MIT). Please see the [LICENSE](https://github.com/adhearsion/adhearsion-i18n/blob/master/LICENSE) file for details.

adhearsion-ivr was created by [Ben Klang](https://twitter.com/bklang) with support from [Mojo Lingo](https://mojolingo.com) and their clients.
