require 'i18n/backend/base'
require 'i18n/backend/active_record/controller_helpers'

module I18n
  module Backend
    class ActiveRecord
      autoload :Missing,     'i18n/backend/active_record/missing'
      autoload :StoreProcs,  'i18n/backend/active_record/store_procs'
      autoload :Translation, 'i18n/backend/active_record/translation'

      module Implementation
        include Base, Flatten

        def available_locales
          Translation.available_locales
        rescue ::ActiveRecord::StatementInvalid
          []
        end

        def store_translations(locale, data, options = {})
          owner_id = options[ENV['owner_assoc_key'].to_sym]
          labels_id = options[:labels_assoc_id]
          draft_labels_id = options[:draft_labels_id]
          options.delete(ENV['owner_assoc_key'].to_sym)
          options.delete(:labels_assoc_id) if options[:labels_assoc_id]
          options.delete(:draft_labels_id) if options[:draft_labels_id]
          escape = options.fetch(:escape, true)
          flatten_translations(locale, data, escape, false).each do |key, value|
            Translation.locale(locale).lookup(expand_keys(key)).delete_all
            attrs = {:locale => locale.to_s, :key => key.to_s, :value => value}
            attrs.merge!(ENV['owner_assoc_key'].to_sym => owner_id) if owner_id
            attrs.merge!(labels_id: labels_id, draft_labels_id: draft_labels_id)
            Translation.create(attrs)
          end
        end

      protected

        def lookup(locale, key, scope = [], options = {})
          key = normalize_flat_keys(locale, key, scope, options[:separator])
          result = Translation.locale(locale).lookup(key).all

          if result.empty?
            nil
          elsif result.first.key == key
            result.first.value
          else
            chop_range = (key.size + FLATTEN_SEPARATOR.size)..-1
            result = result.inject({}) do |hash, r|
              hash[r.key.slice(chop_range)] = r.value
              hash
            end
            result.deep_symbolize_keys
          end

        rescue ::ActiveRecord::StatementInvalid
          # is the translations table missing?
          nil
        end

        # For a key :'foo.bar.baz' return ['foo', 'foo.bar', 'foo.bar.baz']
        def expand_keys(key)
          key.to_s.split(FLATTEN_SEPARATOR).inject([]) do |keys, key|
            keys << [keys.last, key].compact.join(FLATTEN_SEPARATOR)
          end
        end
      end

      include Implementation
    end
  end
end

