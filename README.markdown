Form objects outside your models.

This is a fairly simple gem, and a wrapper around
[Virtus](https://github.com/solnic/virtus). It’s also **experimental**. I have
**not** tested this with Rails 3.


Goals
=====
1. Form objects should work declaratively; but make it easy to override methods
   (like `save`) & include your custom logic.
2. Make it easy to include dependent objects.
3. As little as possible or no ‘magic’; keep it simple.
4. Form objects work with `form_for`, `semantic_form_for`, and other
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

And then go to [http://localhost:3000](http://localhost:3000)


More in-depth docs
==================
I should write this once this gem becomes non-experimental...


Other projects
==============
- [simple_form_object](https://github.com/reinteractive-open/simple_form_object)  
  Seems to be okay, but I wasn’t able to get nested objects to work. Uses a
  slightly different approach.

- [reform](https://github.com/apotonick/reform)  
  Inspiration for this gem; IMHO reform is too large & complicated, and adds too
  much abstraction (‘magic’), while my whole point was to *reduce* the amount of
  magic. I was also unable to satisfactory define a custom `save` method. YMMV
  though.
