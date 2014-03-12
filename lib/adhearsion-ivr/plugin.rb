# encoding: utf-8

class AdhearsionIVR::Plugin < Adhearsion::Plugin
  init :ivr do
    logger.info "Adhearsion IVR loaded"
  end
end
