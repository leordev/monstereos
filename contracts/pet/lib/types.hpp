#pragma once

#include <string>
#include <vector>
#include <eosiolib/eosio.hpp>
#include <eosiolib/asset.hpp>

using std::vector;
using std::map;
using std::string;

using namespace eosio;

namespace types {
  typedef uint64_t uuid;
  typedef uint8_t  battle_mode;
  typedef uint8_t  element_type;

  constexpr uint8_t  PET_TYPES = 109;
  constexpr uint32_t DAY = 86400;
  constexpr uint32_t HOUR = 3600;
  constexpr uint32_t MINUTE = 60;

  // battle modes
  constexpr battle_mode V1 = 1;
  constexpr battle_mode V2 = 2;
  constexpr battle_mode V3 = 3;
  constexpr battle_mode RAID = 100;

  struct st_pet_stat {
    uuid    pet_id;
    uint8_t pet_type;
    name    player;
    uint8_t hp;
  };

  struct st_commit {
    name player;
    checksum256 commitment;
    checksum256 reveal;
  };

  struct st_transfer {
      account_name from;
      account_name to;
      asset        quantity;
      string       memo;
  };

  /* ****************************************** */
  /* ------------ Contract Tables ------------- */
  /* ****************************************** */

  // @abi table pets i64
  struct st_pets {
      uuid id;
      name owner;
      string name;
      uint8_t type;
      uint32_t created_at;
      uint32_t death_at = 0;
      uint32_t last_fed_at;
      uint32_t last_bed_at;
      uint32_t last_awake_at = 0;
      uint32_t last_play_at;
      uint32_t last_shower_at;

      uint64_t primary_key() const { return id; }

      uint64_t get_pets_by_owner() const { return owner.value; }

      bool is_sleeping() const {
          return last_bed_at > last_awake_at;
      }

      bool is_alive() const {
          return death_at == 0;
      }
  };

  typedef multi_index<N(pets), st_pets,
      indexed_by<N(byowner), const_mem_fun<st_pets, uint64_t, &st_pets::get_pets_by_owner>>
  > _tb_pet;

  // @abi table petinbattles i64
  struct st_pet_inbatt {
    uuid     pet_id;

    uint64_t primary_key() const { return pet_id; }
  };
  typedef multi_index<N(petinbattles), st_pet_inbatt> _tb_pet_in_battle;

  // @abi table accounts i64
  struct st_account {
      asset    balance;
      uint64_t primary_key() const { return balance.symbol.name(); }
  };
  typedef multi_index<N(accounts), st_account> _tb_accounts;

  // @abi table elements i64
  struct st_elements {
      uint64_t id;
      vector<uint8_t> ratios = {};

      uint64_t primary_key() const { return id; }
  };
  typedef multi_index<N(elements), st_elements> _tb_elements;

  // @abi table pettypes i64
  struct st_pet_types {
      uint64_t id;
      vector<uint8_t> elements = {};

      uint64_t primary_key() const { return id; }
  };
  typedef multi_index<N(pettypes), st_pet_types> _tb_pet_types;

  // @abi table battles i64
  struct st_battle {
    name                host;
    battle_mode         mode; // 1: 1v1, 2: 2v2, 3: 3v3 :)
    uint32_t            started_at = 0;
    uint32_t            last_move_at = 0;
    vector<st_commit>   commits{};
    vector<st_pet_stat> pets_stats{};

    auto primary_key() const { return host; }

    bool pet_exists(uuid& new_pet) {
      for (const auto& stat : pets_stats) {
        if(stat.pet_id == new_pet)
          return true;
      }

      return false;
    }

    bool const player_exists(name const& player) {
      for (const auto& commit : commits) {
        if(commit.player == player)
          return true;
      }

      return false;
    }

    void remove_player(name const& player) {
      // remove player commitments
      commits.erase(std::remove_if(commits.begin(), commits.end(),
        [&](auto& commit) { return commit.player == player; }),
        commits.end());
    }

    void add_player(name const& player, checksum256 const& commitment) {
      st_commit commit{player, commitment};
      commits.emplace_back(commit);
    }

    void check_turn_and_rotate(name const& player, uint32_t const& tolerance) {
      st_commit& commit = commits[0];

      bool is_idle = (now() - last_move_at) > tolerance;

      eosio_assert(commit.player == player || is_idle, "its not your turn");

      // rotates only if it's the current player
      if (player == commit.player) {
        std::rotate(commits.begin(), commits.begin() + 1, commits.end());
      }
    }

    void add_pet(uuid const& pet_id, uint8_t const& pet_type, name const& player) {
      st_pet_stat pet_stat{pet_id, pet_type, player, 100};
      pets_stats.emplace_back(pet_stat);
    }
  };

  typedef multi_index<N(battles), st_battle> _tb_battle;
}
