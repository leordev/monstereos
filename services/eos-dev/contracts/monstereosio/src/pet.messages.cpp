
void pet::messagefrom(uuid petid, string message) {
    eosio_assert(message.length() <= 255, "E404|message longer than 255");
    auto pc = _get_pet_config();
    auto pet = pets.get(petid, "E404|Invalid petid");
    require_auth(pet.owner);
    eosio_assert(_is_alive(pet, pc), "E404|dead monsters can't message");
}