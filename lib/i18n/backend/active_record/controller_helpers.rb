module I18n
  module Backend
    # Mixin that automatically includes to ApplicationController.
    # The :set_translations_owner_id method can be used for setting
    # ENV['assoc_foreign_key'] with id of translations owner as:
    # before_filter { |c| c.set_translations_owner_id(current_user.id) }
    module ControllerHelpers

      def set_translations_owner_id(id)
        assoc_foreign_key = ENV['translation_assoc_key']
        ENV[assoc_foreign_key] = id.to_s
      end
    end
  end
end
