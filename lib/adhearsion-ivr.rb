# encoding: utf-8

%w{
  version
  plugin
  ivr_controller
}.each { |r| require "adhearsion-ivr/#{r}" }

class AdhearsionIVR
end
