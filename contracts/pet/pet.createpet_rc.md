# CONTRACT FOR pet::createpet

## ACTION NAME: createpet

### Parameters
Input parameters:

* `owner` (person initiating creation)
* `pet_name` (name of monster)

### Intent
INTENT. The intent of the `{{ createpet }}` action is to create a new digital asset with a determined monster type (at the discretion of this monster shop) and transfer ownership to {{ owner }}. The monster will be named {{ pet_name}}.
The created monster has to sleep for 4 hours after creation. The {{ owner }} can only create maximum one monster every hour.

As an authorized party I {{ signer }} wish to have {{ owner }} owning the newly created monster. I understand that {{ owner }} pays for the RAM of 295 bytes used by the monster. Furthermore, I attest under penalty of perjury that {{ owner }} is not afraid of keeping a monster as her pet and that {{ owner }} takes care of the monster while it is alive.

The state of the monster will change over time based on the interaction with the new asset. If the monster is not cared of according to the general rules of monster keeping the monster might die. It starves to death after 20 hours.

### Term
TERM. This Contract expires after the monster died.