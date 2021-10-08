#include "../../includes/link_state.h"
#include "../../includes/route.h"
#include "../../includes/protocol.h"

module LinkStateP{
    provides interface LinkState;
    uses interface Timer<TMilli> as LStimer;
    uses interface NeighborDiscovery;
    uses interface SimpleSend as Sender;
}

implementation {

lsMap map[20];

void advertiseLSP();
void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length);

command void LinkState.bootTimer(){
    call LStimer.startPeriodic(100000);
}

event void LStimer.fired() {
    advertiseLSP();
}



void advertiseLSP(){
    uint8_t i;
    uint8_t advertise[20];
    for(i = 0; i < 20; i++){
        advertise[i] = SENTINEL;
    }

}

void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
    Package->src = src;
    Package->dest = dest;
    Package->TTL = TTL;
    Package->seq = seq;
    Package->protocol = protocol;
    memcpy(Package->payload, payload, length);
}



}