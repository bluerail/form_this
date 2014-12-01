For 1.0:

- Transactions don't seen to work correctly, I get a COMMIT, and then a ROLLBACK
- Warn for parameters that are silently dropped (like Strong Parameters)
- Make sure `self._property_has_many_with_attributes` is correct.
- Finish all docs
- Moar specz!
- Release 1.0!


Perhaps later:

- Add various callbacks in Rails-style (we could then deprecate `set_defaults`)
- In a few places it's tied to ActiveRecord/ActiveModel, but this doesn't have
  to be. Making it independent of Rails might be nice.
