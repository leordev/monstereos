# CONTRACT FOR pet::transferpet

## ACTION NAME: transferpet

### Parameters
Input parameters:

* `pet_id` (identifier of monster)
* `newowner` (name of new owner)

### Intent
INTENT. The intent of the `{{ transferpet }}` action is to transfer ownership of the given monster to {{ newowner }}. Consequently move the cost for RAM of the monster to {{ newowner }}. The ownership transfer has to be confirmed by {{ newowner }} using the `{{ claim }}` action.


### Term
TERM. This Contract expires after {{newowner}} has claimed the ownership or a new `{{ transferpet }}` action was called for the same monster.
