# CONTRACT FOR pet::bidpet

## ACTION NAME: bidpet

### Parameters
Input parameters:

* `pet_id` (identifier of the monster)
* `bidder` (name of the bidder)
* `until` (time when you want to give back the monster to previous owner)
* `amount` (amount of EOS bidder would pay for this bid to be executed)
### Intent
INTENT. The intent of the `{{ bidpet }}` action is to place a binding bid for transfer of ownership of the given monster to {{ bidder }}. The ownership should last until `{{ until }}`. {{bidder}} will pay `{{amount}}` EOS for the transfer.


### Term
TERM. This Contract expires after the bid was matched with an offer and bidder paid the amount or has been removed.
