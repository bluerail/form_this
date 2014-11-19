Form objects outside your models.

This is a fairly simple gem, and a wrapper around
[Virtus](https://github.com/solnic/virtus). It's also somewhat
**experimental**. I have **not** tested this with Rails 3.


Goals:
1. Form objects should work declaratively; but make it easy to override methods
   (like `save`).
2. Make it easy to include dependent objects.
3. As little as possible or no ‘magic’; keep it simple.
4. Form objects work with `form_for`, `semantic_form_for`, and other
   (compatible) form builders.
