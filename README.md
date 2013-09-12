I18n::Backend::ActiveRecord
===========================

Provides ability to store personal translations for each user/other_associated_model
in database and use default translations from yml files if database doesn't contains it.

This repository contains the I18n ActiveRecord backend and support code
that has been extracted from the [I18n gem](https://github.com/svenfuchs/i18n).

Installation
------------

For Bundler put the following in your Gemfile:
```ruby
      gem 'i18n-active_record',
          :git => 'git://github.com/sergeyenin/i18n-active_record.git',
          :branch => 'filters',
          :require => 'i18n/active_record'
```
To load `I18n::Backend::ActiveRecord` into your Rails application,
create a new file in **config/initializers** named **locale.rb**.
A configuration for your locale.rb should look like this:
```ruby
require 'i18n/backend/active_record'

ENV['translation_assoc_key'] = 'user_id' #can be changed to your needs
TRANSLATIONS_STORE = I18n::Backend::ActiveRecord.new
I18n.backend = I18n::Backend::Chain.new(TRANSLATIONS_STORE, I18n.backend)
```

You should generate a migration to create a database table named
`translations`, which will store the localized strings:

```ruby
class CreateTranslations < ActiveRecord::Migration
  def self.up
    create_table :translations do |t|
      t.string :locale
      t.string :key
      t.text   :value
      t.text   :interpolations
      t.boolean :is_proc, :default => false
      t.integer :user_id  # must be the same with ENV['translation_assoc_key']

      t.timestamps
    end
  end

  def self.down
    drop_table :translations
  end
end
```

After that lets provide storing id of current user which will be used for selecting translations.
You can do it yourself and place id of current user to ENV[ENV['translation_assoc_key']],
(ENV['user_id'] in this example).
Gem has a mixin I18n::Backend::ControllerHelpers, that already has following method.
So you can just add this lines to ApplicationController:

```ruby
 include I18n::Backend::ControllerHelpers
 before_filter { |c| c.set_translations_owner_id(current_user.id) }
```

Finally lets provide ability to create translations to our users.
In this example current_user is a devise method.

#####Controller:

```ruby
class TranslationsController < ApplicationController
  def index
    @translations = I18n::Backend::ActiveRecord::Translation.locale(:en).where(user_id: current_user.id)
  end

  def create
    TRANSLATIONS_STORE.store_translations(params[:locale], {params[:key] => params[:value].strip}, current_user.id)
    redirect_to translations_url, :notice => "Added translations"
  end
end
```

#####views/translations/index.rb
```html+erb
<h1>Translations</h1>

<ul>
<% @translations.each do |tr| %>
  <li><%= tr.inspect %></li>
<% end %>
</ul>

<h2>Add Translation</h2>

<%= form_tag translations_path do %>
  <p>
    <%= label_tag :locale %><br />
    <%= text_field_tag :locale %>
  </p>
  <p>
    <%= label_tag :key %><br />
    <%= text_field_tag :key %>
  </p>
  <p>
    <%= label_tag :value %><br />
    <%= text_field_tag :value %>
  </p>
  <p><%= submit_tag "Submit" %></p>
<% end %>
```

Thats it! You are great! Now each user can set his own translations, and your app
will looking for it in database and take it from yaml file if user haven't translation
for same key.

Here you can browse [example app](https://github.com/Kamrad117/i18n-active_record-example) with implementation from readme.
