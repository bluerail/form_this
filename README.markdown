[![Build Status](https://travis-ci.org/bluerail/form_this.svg)](https://travis-ci.org/bluerail/form_this)
[![Dependency Status](https://gemnasium.com/bluerail/form_this.svg)](https://gemnasium.com/bluerail/form_this)
[![Inline docs](http://inch-ci.org/github/bluerail/form_this.svg?branch=master)](http://inch-ci.org/github/bluerail/form_this)

**Form This!** allows you to use form objects outside your models.

This is a fairly simple gem, and a wrapper around
[Virtus](https://github.com/solnic/virtus). It’s **experimental** and may
currently change at any given moment.  
I have **not** tested this with Rails 3, and you will need Ruby 2.0 or newer.


Why?
====
My chief gripe with ActiveRecord is that it can quickly lead to a heavy dose of
spaghetti code when your forms get more complicated. Your validation code may be
spread out of 3, 4, or more models, and to tie it all together, you also need
some code in your controller, part of which may be shared, so that’s a concern
for your controller and/or model. It becomes easy to lose track of what-the-hell
is going on.

With *Form This!*, all your validation code sits in a ‘form object’, your model
will just take care of interfacing with the database. There is a much clearer
‘separation of concerns’.


Goals
-----
1. Form objects should work declaratively; but make it easy to override methods
   & include your custom logic.
1. Make it very easy to include nested record (like Rail’s
   `accepts_nested_attributes_for`, except better).
1. As little as possible ‘magic’; keep it simple.
1. Form objects work with `form_for`, `semantic_form_for`, and other
   (compatible) form builders.
1. Easy & fast to use for small projects and forms, but scale well to large
   projects & forms.


Getting started
===============

Basic workflow
--------------
It should usually be fairly easy replace a ‘normal’ Rails application with *Form
This!*; the basic workflow looks like:

1. You create a new `FormThis` by passing an `ActiveRecord::Base` instance (ie.
   a model). This will be assigned to the `record` attribute. `FormThis` copies
   all the attributes.

1. In your views, almost nothing changes, except that you now use `@form` with
   `form_for`.

1. You use `form.validate(params[:artist])` to assign values to the form, this
   will set errors (if any), and return a boolean indicating if the form is
   valid. Note that nothing is update on the record yet.

1. You can call `update_record` to copy attributes from the form to the record;
   nothing is persisted to the database.

1. Call `persist!` to persist the record to the database. You often want to
   override this method to *also* persist nested forms (which is *not*
   automagically done for you).

1. You typically want to call the `save` method, but this just calls
   `update_record` & `persist!`.


What it actually looks like
---------------------------
**`app/models/artist.rb`**:

```ruby
class Artist < ActiveRecord::Base
  has_many :albums
end
```

**`app/models/album.rb`**:

```ruby
class Album < ActiveRecord::Base
  belongs_to :artist
end
```

**`app/forms/artist_form.rb`**

```ruby
class ArtistForm < FormThis::Base
  # The default type is String
  property :name, validates: { presence: true }

  # Allow an Array of AlbumForms
  property :albums, type: Array[AlbumForm]

  # Make sure there is at least one album so that the form for this gets built
  def set_defaults
    @record.albums.build if @record.albums.blank?
  end

  # We don't persist nested form automatically; you need to do that manually.
  # This is feature :-)
  def persist!
    @record.transaction do
      @record.save
      self.albums.each(&:save)
    end
  end
end
```

**`app/forms/album_form.rb`**:

```ruby
class AlbumForm < FormThis::Base
  property :name, validates: { presence: true }
end
```

**`app/controller/artists_controller`**:

```ruby
class ArtistsController
  def new
    @form = ArtistForm.new Artist.new
  end

  def create
    @form = ArtistForm.new Artist.new

    # Note using Rail’s strong parameters here. They’re no longer required,
    # since we already explicitly define which attributes may be assigned in
    # our form object, so using it would be redundant.
    if @form.validate(params[:artist]) && @form.save
      redirect_to @form
    else
      render action: :new
    end
  end

  def edit
    @form = ArtistForm.new Artist.find(params[:id])
  end

  def update
    @form = ArtistForm.new Artist.find(params[:id])
    if @form.validate(params[:artist]) && @form.save
      redirect_to @form
    else
      render action: :edit
    end
  end
end
```


**`app/views/artists/news.html.erb`**:

```erb
<%= form_for @form do |f| %>
  <% = f.input do %>
    <%= f.input :name %>
  <% end %>
<% end %>
```


As you see, it’s very similar to a ‘normal’ rails application; you just use
swap `@record` with `@form` in a few places, and put your validations in a *Form
This!* instead of a model.


Demo app
--------
There is a simple rails app for demonstration & testing purposes at
[form_this_demo](https://github.com/bluerail/form_this_demo).


Options
-------
- `FormThis.protect_form_for`  
  If you're using `FormThis`, you never want to pass an `ActiveRecord` instance
  to `form_for`, doing so can lead to strange behaviour, even stranger errors,
  and -worst of all- invalid records in your database (since validations are now
  done by *Form This!*, and not your models).

  This monkey patches `form_for` to protect you from this; an `Exception` will be
  raised if anything other than a `FormThis::Base` instance is passed. This will
  also work for form builders that use `form_for` internally (such as
  Formtastic).

  This is enabled by default, but you can pass `disable_protection` to the
  `form_for` call to disable. You can also disable it globally if you don’t want
  protection or monkey patching is against the tenants of your faith, but this
  is not recommended.

- `FormThis.foreign_key_aliases`  
  If you use a model as a type, we also try to make aliases for the foreign key
  (if any). This is required for Formtastic to work properly. If is enabled by
  default.

Tips
====

## delegate
You can use [delegate][delegate] to delegate or proxy functions to your record,
for example:

```ruby
class Person < ActiveRecord::Base
  def full_name
    "#{self.first_name} #{self.last_name}"
  end

  def has_address?
    self.address.present?
  end
end
```

```ruby
class PersonForm < FormThis::Base
  delegate :full_name, :has_address?, to: :record
end
```

[delegate]: http://api.rubyonrails.org/classes/Module.html#method-i-delegate


## Data normalization

You can use [Virtus' custom coercions][coercions] with Form This!. For example:

```ruby
class IbanType < Virtus::Attribute
  # Remove spaces from IBAN account numbers
  def coerce v
    v.respond_to?(:to_s) ? v.to_s.gsub(/\s+/, '') : v
  end
end
```

```ruby
class PersonForm > FormThis::Base
  propery :iban, type: IbanType
end
```

[coercions]: https://github.com/solnic/virtus#custom-coercions


TODO
====
Before a 1.0 release, we need to:

- Write good tests
- Provide proper `{before,after}_*` callbacks
- Make the demo app better, show *all* of the features
- Make sure `self._property_has_many_with_attributes` is correct.
- `grep -r TODO` and fix it all
- Also test simple_form and perhaps some other form builders
- Methods from AR to check/copy:
  - ==, ===, <=>, hash, pp
  - changed?, destroyed? and related
  - more? How AR-compatible do we want to be?
- validating unique doesn't work (only works with AR)
- Test with strange properties which don't correspond to the record; show
  meaningfull errors here

Thing I'd like to do later (perhaps):

- In a few places it's tied to `ActiveRecord`/`ActiveModel`, but this doesn't
  have to be. Making it independent of Rails might be nice.

Similar projects
================
- [reform](https://github.com/apotonick/reform)  
  Inspiration for this gem; IMHO reform is too large & complicated, and adds too
  much abstraction (‘magic’), while my whole point was to *reduce* the amount of
  magic. I was also unable to satisfactory define a custom `save` method. YMMV
  though.

- [simple_form_object](https://github.com/reinteractive-open/simple_form_object)  
  Seems to be okay, but I wasn’t able to get nested objects to work. Uses a
  slightly different approach.
