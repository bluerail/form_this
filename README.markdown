[![Build Status](https://travis-ci.org/bluerail/form_this.svg)](https://travis-ci.org/bluerail/form_this)
[![Dependency Status](https://gemnasium.com/bluerail/form_this.svg)](https://gemnasium.com/bluerail/form_this)
[![Inline docs](http://inch-ci.org/github/bluerail/form_this.svg?branch=master)](http://inch-ci.org/github/bluerail/form_this)

**Form This!** allows you to use form objects outside your models.

This is a fairly simple gem, and a wrapper around
[Virtus](https://github.com/solnic/virtus). It’s also **experimental**. I have
**not** tested this with Rails 3, and you will need Ruby 2.0 or newer.


Goals
=====
1. Form objects should work declaratively; but make it easy to override methods
   (like `save`) & include your custom logic.
1. Make it very easy to include nested record (like Rail's
   `accepts_nested_attributes_for`; except better).
1. As little as possible ‘magic’; keep it simple.
1. Form objects work with `form_for`, `semantic_form_for`, and other
   (compatible) form builders.


What it looks like
==================

`app/models/artist.rb`

    class Artist < ActiveRecord::Base
      has_many :albums
    end

`app/models/album.rb`

    class Album < ActiveRecord::Base
      belongs_to :artist
    end

`app/forms/artist_form.rb`

    class ArtistForm < FormThis::Base
      property :name, validates: { presence: true }
      property :albums, type: Array[AlbumForm]

      # Make sure there is at least one album so that the form for this gets built
      def set_defaults
        @record.albums.build if @record.albums.blank?
      end
    end

`app/forms/album_form.rb`

    class AlbumForm < FormThis::Base
      property :name, validates: { presence: true }
    end

You create a new `FormThis` by passing something that looks like an
`ActiveModel` (usually an `ActiveRecord::Base` instance, but this is not
strictly required).

You can then use `@form.validate(params[:artist])` to assign values to the form,
this will set errors (if any), and return a boolean indicating if the form is
valid. Note that nothing is done with the record yet.

You can then `save` to copy the attributes to the underlying record, and persist
it to the database.

In a controller, it looks like:

    class ArtistsController
      def new
        @form = ArtistForm.new Artist.new
      end

      def create
        @form = ArtistForm.new @artist
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


In your views, nothing changes, except that you now use `@form` with `form_for`:

    <%= form_for @form do |f| %>
      <% = f.input do %>
        <%= f.input :name %>
      <% end %>
    <% end %>


Note that I’m not using Rail’s strong parameters here. They’re mot longer
required, since we already explicitly define which attributes may be assigned in
our form object, so using it would be redundant.


Demo app
--------
There is a simple rails app for demonstration & testing purposes at
[form_this_demmo](https://github.com/bluerail/form_this_demo).


More in-depth docs
==================
I should write this once this gem becomes non-experimental...


Options
-------
- `FormThis.protect_form_for`  
  If you're using `FormThis`, you never want to pass an `ActiveRecord` instance
  to `form_for`, doing so can lead to strange behaviour, even stranger errors,
  and -worst of all- invalid records in your database (since validations are now
  done by Form This!, and not your models).

  This monkeypatches `form_for` to protect you from this; an `Exception` will be
  raised if anything other than a `FormThis::Base` instance is passed. This will
  also work for form builders that use `form_for` internally (such as
  Formtastic).

  This is enabled by default, you can disable it if you don’t want protection or
  monkey patching is against the tenants of your faith, but this is not
  recommended.


Other projects
==============
- [reform](https://github.com/apotonick/reform)  
  Inspiration for this gem; IMHO reform is too large & complicated, and adds too
  much abstraction (‘magic’), while my whole point was to *reduce* the amount of
  magic. I was also unable to satisfactory define a custom `save` method. YMMV
  though.

- [simple_form_object](https://github.com/reinteractive-open/simple_form_object)  
  Seems to be okay, but I wasn’t able to get nested objects to work. Uses a
  slightly different approach.
