require 'test_helper'

class I18nActiveRecordMissingTest < Test::Unit::TestCase
  class Backend < I18n::Backend::ActiveRecord
    include I18n::Backend::ActiveRecord::Missing
  end

  def setup
    ENV['owner_assoc_key'] = 'user_id'
    ENV['user_id'] = 2.to_s
    I18n.backend.store_translations(:en, :bar => 'Bar', :i18n => { :plural => { :keys => [:zero, :one, :other] } })
    I18n.backend = I18n::Backend::Chain.new(Backend.new, I18n.backend)
    I18n::Backend::ActiveRecord::Translation.delete_all
  end

  test "can persist interpolations" do
    translation = I18n::Backend::ActiveRecord::Translation.new(:key => 'foo', :value => 'bar', :locale => :en)
    translation.interpolations = %w(count name)
    translation.save
    assert translation.valid?
  end

  test "lookup persists the key" do
    I18n.t('foo.bar.baz')
    assert_equal 1, I18n::Backend::ActiveRecord::Translation.count
    assert I18n::Backend::ActiveRecord::Translation.locale(:en).find_by_key('foo.bar.baz')
  end

  test "lookup does not persist the key twice" do
    2.times { I18n.t('foo.bar.baz') }
    assert_equal 1, I18n::Backend::ActiveRecord::Translation.count
    assert I18n::Backend::ActiveRecord::Translation.locale(:en).find_by_key('foo.bar.baz')
  end

  test "lookup persists interpolation keys when looked up directly" do
    I18n.t('foo.bar.baz', :cow => "lucy" )  # creates stub translation.
    translation_stub = I18n::Backend::ActiveRecord::Translation.locale(:en).lookup('foo.bar.baz').first
    assert translation_stub.interpolates?(:cow)
  end

  test "creates one stub per pluralization" do
    I18n.t('foo', :count => 999)
    translations = I18n::Backend::ActiveRecord::Translation.locale(:en).find_all_by_key %w{ foo.zero foo.one foo.other }
    assert_equal 3, translations.length
  end

  test "creates no stub for base key in pluralization" do
    I18n.t('foo', :count => 999)
    assert_equal 3, I18n::Backend::ActiveRecord::Translation.locale(:en).lookup("foo").count
    assert !I18n::Backend::ActiveRecord::Translation.locale(:en).find_by_key("foo")
  end

  test "creates a stub when a custom separator is used" do
    I18n.t('foo|baz', :separator => '|')
    I18n::Backend::ActiveRecord::Translation.locale(:en).lookup("foo.baz").first.update_attributes!(:value => 'baz!')
    assert_equal 'baz!', I18n.t('foo|baz', :separator => '|')
  end

  test "creates a stub per pluralization when a custom separator is used" do
    I18n.t('foo|bar', :count => 999, :separator => '|')
    translations = I18n::Backend::ActiveRecord::Translation.locale(:en).find_all_by_key %w{ foo.bar.zero foo.bar.one foo.bar.other }
    assert_equal 3, translations.length
  end

  test "creates a stub when a custom separator is used and the key contains the flatten separator (a dot character)" do
    key = 'foo|baz.zab'
    I18n.t(key, :separator => '|')
    I18n::Backend::ActiveRecord::Translation.locale(:en).lookup("foo.baz\001zab").first.update_attributes!(:value => 'baz!')
    assert_equal 'baz!', I18n.t(key, :separator => '|')
  end

  test 'lookup do not returns translations of other users' do
    I18n::Backend::ActiveRecord::Translation.create!(locale: :en, key: 'kam', value: 'rad', user_id: 1)
    assert_equal [], I18n::Backend::ActiveRecord::Translation.locale(:en).lookup('kam')
  end

  test 'lookup returns translations of current user' do
    I18n::Backend::ActiveRecord::Translation.create!(locale: :en, key: 'kam', value: 'rad', user_id: 2)
    assert_equal 'rad', I18n::Backend::ActiveRecord::Translation.locale(:en).lookup('kam').first.value
  end

  test 'lookup found nothing if id of association does not stored in ENV' do
    ENV.delete('user_id')
    I18n::Backend::ActiveRecord::Translation.create!(locale: :en, key: 'kam', value: 'rad', user_id: 2)
    assert_equal [], I18n::Backend::ActiveRecord::Translation.locale(:en).lookup('kam')
  end

  test 'lookup found nothing if translation_assoc_key does not stored in ENV' do
    ENV.delete('owner_assoc_key')
    I18n::Backend::ActiveRecord::Translation.create!(locale: :en, key: 'kam', value: 'rad', user_id: 2)
    assert_raises(TypeError) { I18n::Backend::ActiveRecord::Translation.locale(:en).lookup('kam') }
  end

end if defined?(ActiveRecord)
