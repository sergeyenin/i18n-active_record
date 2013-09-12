require 'i18n'

ApplicationController.send(:include, I18n::Backend::ControllerHelpers)
