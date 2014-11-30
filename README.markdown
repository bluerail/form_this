Form This! allows you to use form objects outside your models.

This is a fairly simple gem, and a wrapper around
[Virtus](https://github.com/solnic/virtus). It’s also **experimental**. I have
**not** tested this with Rails 3.


Goals
=====
1. Form objects should work declaratively; but make it easy to override methods
   (like `save`) & include your custom logic.
1. Make it very easy to include nested record (like Rail's
   `accepts_nested_attributes_for`).
1. As little as possible ‘magic’; keep it simple.
1. Form objects work with `form_for`, `semantic_form_for`, and other
   (compatible) form builders.


What it looks like
==================

Demo app
--------
There is a simple rails app for demonstration/testing purposes in the `demo/`
directory; you can start it with:

    cd demo
    bundle install --path vendor/bundle
    bundle exec rake db:migrate
    bundle exec rails server

And then go to [http://localhost:3000](http://localhost:3000). The interesting
files to look at are in `app/forms/`](app/forms/).


More in-depth docs
==================
I should write this once this gem becomes non-experimental...


TODO
----
If you do use `form_for` with a “plain” AR instead of a Form This! object you
might get strange errors, and worse may end up with an invalid model in your
database.  
We should make this impossible/difficult; perhaps add a check to the `form_for`
method or ActiveRecord?


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
