# [develop](https://github.com/adhearsion/adhearsion-ivr)
  * Feature: Added support for input options to be passed to ask
  * Feature: Added support for output options to be passed to ask
  * Feature: Repeat prompts should not be interruptible. In cases where the first response to a prompt is not a match, it is likely that the issue was with background noise or excessive sensitivity. Such conditions with repeat prompts can lead to a bouncing behaviour. Removing the potential entirely for feedback of the prompt into input can help here, but even in cases where it doesn't, the absence of very short repeat prompts (of circa 1 second) makes for a more graceful failure. This behaviour can be disabled by setting `barge false` on your controller class.

# [v0.2.0](https://github.com/adhearsion/adhearsion-ivr/compare/0.1.0...0.2.0) - [2015-03-27](https://rubygems.org/gems/adhearsion-ivr/versions/0.2.0)
  * Feature: Added support for defining alternative prompt resolution algorithms by overriding `#prompts`
  * Feature: Added support for overriding `#max_attempts`
  * Feature: Added support for specifying a timeout using #timeout
  * Feature: Added support for specifying a grammar URL using #grammar_url
  * Feature: Added support for specifying a validation callback
  * Feature: Added support for specifying a `renderer`

# [v0.1.0](https://github.com/adhearsion/adhearsion-ivr/compare/2c7ff73f5d6471be23e291c7d6c7b61d0128e09a...0.1.0) - [2014-03-12](https://rubygems.org/gems/adhearsion-ivr/versions/0.1.0)
  * Initial release
