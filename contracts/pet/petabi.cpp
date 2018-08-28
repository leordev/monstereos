#include "pet.cpp"
// DO NOT include transferpet into the abi, as it is only for internal use.
EOSIO_ABI(pet, (createpet)(updatepet)(feedpet)(bedpet)(awakepet)(destroypet)(battlecreate)(battlejoin)(battleleave)(battlestart)(battleselpet)(battleattack)(battlefinish)(addelemttype)(changeelemtt)(addpettype)(changepettyp)(changecrtol)(changebatma)(changebatidt)(changebatami)(changebatama)(transfer))
