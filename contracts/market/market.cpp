#include "market.hpp"

void market::offerpet(uuid pet_id, name newowner, uint32_t until = 0, uint64_t amount = 0) {
    const auto& pet = pets.get(pet_id, "E404|Invalid pet");

    require_auth(pet.owner);
    eosio_assert(pet.owner != newowner, "new owner must be different than current owner");

    auto idx_existent_offer = offers.get_index<N(by_user_and_pet)>();
    auto user_pet_id = combine_ids(pet.owner, pet_id);
    auto itr_user_pet = idx_existent_offer.find(user_pet_id);
    uint32_t placed_at = now();
    uint8_t type;
    if (until > 0) {
        eosio_assert(until > placed_at, "E404|End of temporary transfer must be in the future");
        type = 11; // temporary transfer
    } else {
        type = 1; // indefinite transfer
    }
    if (itr_user_pet != idx_existent_offer.end()) {
        auto offer = *itr_user_pet;
        eosio_assert(offer.type != 10, "E404|offer can't be updated during temporary transfers");
        // eosio_assert(offer.type == 1, "you can't ask and bid at the same time. (should not happen anyway)");
        offers.modify(*itr_user_pet, pet.owner, [&](auto &r) {
            r.value = asset(amount, S(4,EOS));
            r.new_owner = newowner;
            r.type = type;
            r.placed_at = placed_at;
            r.transfer_ends_at = until;
        });
    } else {
        offers.emplace(pet.owner, [&](auto& r){            
            st_offers offer {
                .id = offers.available_primary_key(),
                .user = pet.owner,
                .new_owner = newowner,
                .pet_id = pet.id,
                .type = type,
                .value = asset(amount, S(4,EOS)),
                .placed_at = placed_at,
                .ends_at = 0,
                .transfer_ends_at = until};
            r = offer;
        });
    }

    print("new owner can become ", newowner);
}

void market::removeoffer(name owner, uuid pet_id) {
    auto idx_existent_offer = offers.get_index<N(by_user_and_pet)>();
    const auto& offer = idx_existent_offer.get(combine_ids(owner, pet_id), "E404|Invalid offer");
    
    eosio_assert(offer.type != 10, "E404|offers can't be removed during temporary transfers");

    require_auth(owner);
    offers.erase(offer);
}

void market::claimpet(name oldowner, uuid pet_id) {
    auto idx_existent_offer = offers.get_index<N(by_user_and_pet)>();
    const auto& offer = idx_existent_offer.get(combine_ids(oldowner, pet_id), "E404|Invalid offer");
    const auto& pet = pets.get(pet_id, "E404|Invalid pet");

    const name newowner = offer.new_owner;
    eosio_assert(newowner != (const name) {0}, "E404|Offer not personalized");
    eosio_assert(oldowner == pet.owner, "E404|Pet already transferred");
    
    require_auth(newowner);
    eosio_assert(offer.type != 10 || offer.transfer_ends_at < now(), "E404|Temporary transfer not yet over");
    eosio_assert(offer.value.amount == 0, "E404|Offers requires value transfer");
    action(permission_level{_self, N(active)}, N(monstereosio), N(transferpet), std::make_tuple(pet.id, newowner)).send();
    
    if (offer.transfer_ends_at > 0) {
        if (offer.type == 11) {
            offers.modify(offer, 0, [&](auto& r){
                r.user = newowner;
                r.new_owner = oldowner;
                r.value = asset(0); // transfer back is for free
                r.type = 10;
            });
            print("offer converter to temporary transfer");
        } else if (offer.type == 10) {
            offers.erase(offer);
            print("offer erased.");
        }
    } else {
        offers.erase(offer);
        print("offer erased.");
    }
}

void market::bidpet(uuid pet_id, name bidder, uint32_t until = 0, uint64_t amount = 0) {
    const auto& pet = pets.get(pet_id, "E404|Invalid pet");

    require_auth(bidder);
    eosio_assert(pet.owner != bidder, "bidder must be different than current owner");

    auto idx_existent_offer = offers.get_index<N(by_user_and_pet)>();
    auto user_pet_id = combine_ids(bidder, pet_id);
    auto itr_user_pet = idx_existent_offer.find(user_pet_id);
    uint32_t placed_at = now();
    uint8_t type;
    if (until > 0) {
        type = 12; // temporary transfer
    } else {
        type = 2; // indefinite transfer
    }
    if (itr_user_pet != idx_existent_offer.end()) {
        auto offer = *itr_user_pet;
        // eosio_assert(offer.type == 2, "you can't ask and bid at the same time. (should not happen anyway)");
        offers.modify(*itr_user_pet, pet.owner, [&](auto &r) {
            r.value = asset(amount);
            r.placed_at = placed_at;
            r.transfer_ends_at = until;
        });
    } else {
        offers.emplace(bidder, [&](auto& r){            
            st_offers offer {
                .id = offers.available_primary_key(),
                .user = bidder,
                .pet_id = pet.id,
                .type = type,
                .value = asset(amount),
                .placed_at = placed_at,
                .ends_at = 0,
                .transfer_ends_at = until};
            r = offer;
        });
    }
}

void market::removebid(name bidder, uuid pet_id) {
    auto idx_existent_offer = offers.get_index<N(by_user_and_pet)>();
    const auto& offer = idx_existent_offer.get(combine_ids(bidder, pet_id), "E404|Invalid offer");
    
    require_auth(bidder);
    offers.erase(offer);
}

EOSIO_ABI(market, (offerpet)(removeoffer)(claimpet)(bidpet)(removebid))