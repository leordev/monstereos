using namespace types;
using namespace utils;

void pet::battlecreate(name host, battle_mode mode, checksum256 secret) {
  require_auth(host);

  _tb_battle tb_battles(_self, _self);
  auto itr_battle = tb_battles.find(host);

  eosio_assert(itr_battle == tb_battles.end(), "you already host a battle!");
  eosio_assert(mode == V1 || mode == V2 || mode == V3, "invalid battle mode");

  // check and increase busy arenas counter
  auto pc = _get_pet_config();
  pc.battle_busy_arenas++;
  eosio_assert(pc.battle_busy_arenas <= pc.battle_max_arenas, "all arenas are busy");

  tb_battles.emplace(_self, [&](auto& r) {
    r.host = host;
    r.mode = mode;
  });
  _update_pet_config(pc);

  SEND_INLINE_ACTION( *this, battlejoin, {host,N(active)}, {host, host, secret} );
}

void pet::battlejoin(name host, name player, checksum256 secret) {

  require_auth(player);

  _tb_battle tb_battles(_self, _self);
  auto itr_battle = tb_battles.find(host);
  eosio_assert(itr_battle != tb_battles.end(), "battle not found for current host");
  st_battle battle = *itr_battle;

  eosio_assert(!battle.player_exists(player), "player is already in this battle");
  eosio_assert(battle.commits.size() < 2, "battle is already full of players");

  battle.add_player(player, secret);

  tb_battles.modify(itr_battle, _self, [&](auto& r) {
    r.commits = battle.commits;
  });

}

void pet::battleleave(name host, name player) {

  require_auth(player);

  _tb_battle tb_battles(_self, _self);
  auto itr_battle = tb_battles.find(host);
  eosio_assert(itr_battle != tb_battles.end(), "battle not found for current host");
  st_battle battle = *itr_battle;

  eosio_assert(battle.started_at == 0, "battle already started");

  eosio_assert(battle.player_exists(player), "player not in this battle");

  if (player == host) {
    tb_battles.erase( itr_battle );

    // decrease busy arenas counter
    auto pc = _get_pet_config();
    pc.battle_busy_arenas--;
    _update_pet_config(pc);

  } else {
    battle.remove_player(player);
    tb_battles.modify(itr_battle, 0, [&](auto& r) {
      r.commits = battle.commits;
    });
  }

}

void pet::battlestart(name host, name player, checksum256 source) {

  require_auth(player);

  _tb_battle tb_battles(_self, _self);
  auto itr_battle = tb_battles.find(host);
  eosio_assert(itr_battle != tb_battles.end(), "battle not found for current host");
  st_battle battle = *itr_battle;

  eosio_assert(battle.started_at == 0, "battle already started");
  eosio_assert(battle.commits.size() == 2, "battle has not enough players");

  // validates and summarize reveals
  bool valid_reveal = false;
  vector<st_commit> reveals{};
  for(auto& commit : battle.commits) {
    if (commit.player == player) {
      eosio_assert(is_zero(commit.reveal), "commit was already revealed");

      assert_sha256( (char *)&source, sizeof(source),
        (const checksum256 *)&commit.commitment );
      commit.reveal = source;
      reveals.emplace_back(commit);
      valid_reveal = true;
    } else if (!is_zero(commit.reveal)) {
      reveals.emplace_back(commit);
    }
  }
  eosio_assert(valid_reveal, "invalid reveal");

  // everybody commited, randomize all turns by random commits
  if (reveals.size() == battle.commits.size()) {
    std::sort (reveals.begin(), reveals.end(),
      [](const st_commit &a, const st_commit &b) -> bool {
        checksum256 result;
        sha256( (char *)&a, sizeof(b)*2, &result);
        return result.hash[1] < result.hash[0];
      });
    battle.started_at = now();
    battle.last_move_at = now();
    battle.commits = reveals;
  }

  tb_battles.modify(itr_battle, 0, [&](auto& r) {
    r.started_at = battle.started_at;
    r.last_move_at = battle.last_move_at;
    r.commits = battle.commits;
  });
}

void pet::battleselpet(name host, name player, uuid pet_id) {
  require_auth(player);

  _tb_battle tb_battles(_self, _self);
  auto itr_battle = tb_battles.find(host);
  eosio_assert(itr_battle != tb_battles.end(), "battle not found for current host");
  st_battle battle = *itr_battle;

  eosio_assert((battle.mode == V1 && battle.pets_stats.size() < 2) ||
    (battle.mode == V2 && battle.pets_stats.size() < 4) ||
    (battle.mode == V3 && battle.pets_stats.size() < 6),
    "all pets were selected already");

  auto pc = _get_pet_config();
  battle.check_turn_and_rotate(player, pc.battle_idle_tolerance);

  auto itr_pet = pets.find(pet_id);
  eosio_assert(itr_pet != pets.end(), "E404|Invalid pet");
  st_pets pet = *itr_pet;

  // only owners can make fight with pets
  require_auth(pet.owner);
  eosio_assert(pet.is_alive(), "dead pets don't battle");
  eosio_assert(!pet.is_sleeping(), "sleeping pets don't battle");

  auto itr_pet_battle = petinbattles.find(pet_id);
  eosio_assert(itr_pet_battle == petinbattles.end(), "pet is already in another battle");
  petinbattles.emplace(_self, [&](auto& r) {
    r.pet_id = pet_id;
  });

  battle.add_pet(pet_id, pet.type, player);

  tb_battles.modify(itr_battle, 0, [&](auto& r) {
    r.pets_stats = battle.pets_stats;
    r.commits = battle.commits;
    r.last_move_at = now();
  });

}

void pet::battleattack(name         host,
                       name         player,
                       uuid         pet_id,
                       uuid         pet_enemy_id,
                       element_type element_id) {

  require_auth(player);

  _tb_battle tb_battles(_self, _self);
  auto itr_battle = tb_battles.find(host);
  eosio_assert(itr_battle != tb_battles.end(), "battle not found for current host");
  st_battle battle = *itr_battle;

  auto pc = _get_pet_config();

  // check and rotate turn only if player is not idle
  battle.check_turn_and_rotate(player, pc.battle_idle_tolerance);

  // get current pet and enemy types
  uint8_t pet_type{0};
  uint8_t pet_enemy_type_id{0};
  bool valid_pet = false;
  for (const auto& pet_stat : battle.pets_stats) {
    if (pet_stat.pet_id == pet_id) {
      eosio_assert(pet_stat.player == player, "you cannot control this monster");
      eosio_assert(pet_stat.hp > 0, "this monster is dead");
      pet_type = pet_stat.pet_type;
      valid_pet = true;
    } else if (pet_stat.pet_id == pet_enemy_id) {
      pet_enemy_type_id = pet_stat.pet_type;
    }
  }

  eosio_assert(valid_pet, "invalid attack");

  const auto& attack_pet_types = pettypes.get(pet_type, "invalid pet type");
  bool valid_element = false;
  for (const auto& pet_element : attack_pet_types.elements) {
    if (pet_element == element_id) {
      valid_element = true;
      break;
    }
  }
  eosio_assert(valid_element, "invalid attack element");

  // cross ratio elements to enemy pet elements
  uint8_t ratio{5}; // default ratio
  const auto& attack_element = elements.get(element_id, "invalid element");
  const auto& pet_enemy_types = pettypes.get(pet_enemy_type_id, "invalid pet enemy type");
  for (const auto& pet_element : pet_enemy_types.elements) {
    const auto& type_ratio = attack_element.ratios[pet_element];
    ratio = type_ratio > ratio ? type_ratio : ratio;
  }

  // random factor to attack
  checksum256 result;
  sha256( (char *)&battle.commits[0], sizeof(battle.commits[1])*2, &result);
  uint8_t factor = (result.hash[1] + result.hash[0] + now()) %
    (pc.attack_max_factor + 1 - pc.attack_min_factor) + pc.attack_min_factor;

  // damage based on element ratio and factor
  uint8_t damage = factor * ratio / 10;
  print("\nattack results ====\nattack damage: ", int{damage},
    "\nelement ratio: ", int{ratio},
    "\nattack factor: ", int{factor});

  // updates pet hp and finish attack turn
  std::map<name, uint8_t> alive_pets{};
  for (auto& pet_stat : battle.pets_stats) {
    if (pet_stat.pet_id == pet_enemy_id) {
      pet_stat.hp = damage > pet_stat.hp ? 0 : pet_stat.hp - damage;
    }

    // update alive pets
    uint8_t alive_counter = pet_stat.hp > 0 ? 1 : 0;
    auto [it, success] = alive_pets.insert(
      std::make_pair(pet_stat.player, alive_counter));
    if (!success) {
      it-> second = it->second + alive_counter;
    }

    print("\npet: ", pet_stat.pet_id, " - hp: ", int{pet_stat.hp});
  }

  // check battle end
  uint8_t players_alive{0};
  name winner{};
  for (auto const& [player, pets_alive] : alive_pets) {
    if (pets_alive > 0) {
      players_alive++;
      winner = player;
    }
  }

  // modify stats and goes to next turn or end battle
  if (players_alive > 1) {
    tb_battles.modify(itr_battle, 0, [&](auto& r) {
      r.pets_stats = battle.pets_stats;
      r.commits = battle.commits;
      r.last_move_at = now();
    });
  } else {
    // we need an action here?
    print(" and the winner is >>> ", winner);
    SEND_INLINE_ACTION( *this, battlefinish, {_self,N(active)}, {host, winner} );
  }

}

void pet::battlefinish(name host, name /* winner */) {
  require_auth(_self);

  _tb_battle tb_battles(_self, _self);
  auto itr_battle = tb_battles.find(host);
  eosio_assert(itr_battle != tb_battles.end(), "battle not found for current host");
  st_battle battle = *itr_battle;

  // update pets stats and remove from battle
  for (st_pet_stat ps : battle.pets_stats) {
    auto itr_pet_battle = petinbattles.find(ps.pet_id);
    eosio_assert(itr_pet_battle != petinbattles.end(), "E404|Invalid pet battle stat");
    petinbattles.erase( itr_pet_battle );
  }

  tb_battles.erase( itr_battle );

  // decrease busy arenas counter
  auto pc = _get_pet_config();
  pc.battle_busy_arenas--;
  _update_pet_config(pc);

}
