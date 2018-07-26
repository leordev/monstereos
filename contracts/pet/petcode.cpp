#include "pet.cpp"

#define EOSIO_ABI_EX( TYPE, MEMBERS ) \
extern "C" { \
   void apply( uint64_t receiver, uint64_t code, uint64_t action ) { \
      if( action == N(onerror)) { \
         /* onerror is only valid if it is for the "eosio" code account and authorized by "eosio"'s "active permission */ \
         eosio_assert(code == N(eosio), "onerror action's are only valid from the \"eosio\" system account"); \
      } \
      auto self = receiver; \
      if( code == self || code == N(eosio.token) || action == N(onerror) ) { \
         TYPE thiscontract( self ); \
         switch( action ) { \
            EOSIO_API( TYPE, MEMBERS ) \
         } \
         /* does not allow destructor of thiscontract to run: eosio_exit(0); */ \
      } \
   } \
}

EOSIO_ABI_EX(pet,
    // pet core
    (createpet)
    (updatepet)
    (feedpet)
    (bedpet)
    (awakepet)
    (destroypet)
    (transferpet)

    // battles
    (battlecreate)
    (battlejoin)
    (battleleave)
    (battlestart)
    (battleselpet)
    (battleattack)
    (battlefinish)

    // admins and config setup
    (addelemttype)
    (changeelemtt)
    (addpettype)
    (changepettyp)
    (changecrtol)
    (changebatma)
    (changebatidt)
    (changebatami)
    (changebatama)

    // tokens deposits
    (transfer)
)
