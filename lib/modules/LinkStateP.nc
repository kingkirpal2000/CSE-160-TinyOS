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

uint8_t linkState[100][100];
Route routingTable[100];
uint16_t numKnownNodes = 0;
uint16_t numRoutes = 0;
uint16_t sequenceNum = 0;
pack routePack;

void advertiseLSP();
void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length);

command void LinkState.bootTimer(){
    call LStimer.startOneShot(40000);
}

event void LStimer.fired() {
    uint8_t i, j;
    if(call LStimer.isOneShot()) {
        for(i = 0; i < 100; i++){
            routingTable[i].NH = 0;
            routingTable[i].cost = 20;
        }
        for(i = 0; i < 100; i++) {
            linkState[i][0] = 0;
        }
        for(i = 0; i < 100; i++) {
            linkState[0][i] = 0;
        }
        for(i = 1; i < 100; i++) {
            for(j = 1; j < 100; j++) {
                linkState[i][j] = 20;
            }
        }

        routingTable[TOS_NODE_ID].NH = TOS_NODE_ID;
        routingTable[TOS_NODE_ID].cost = 0;
        linkState[TOS_NODE_ID][TOS_NODE_ID] = 0;
        numKnownNodes++;
        numRoutes++;
        call LStimer.startPeriodic(30000);
    } else {
        advertiseLSP();
    }
}



void advertiseLSP(){
    ls linkStatePayload[10];
    uint32_t* neighbors = call NeighborDiscovery.printNeighbors();
    uint16_t neighborsListSize = call NeighborDiscovery.neighborSize();
    uint16_t i = 0, counter = 0, j = 0;

    // Zero out the array
    for(i = 0; i < 10; i++) {
        linkStatePayload[i].neighbor = 0;
        linkStatePayload[i].cost = 0;
    }

    // Add neighbors in groups of 10 and flood LSP to all neighbors
    for(i = 0; i < neighborsListSize; i++) {
        linkStatePayload[counter].neighbor = neighbors[i];
        linkStatePayload[counter].cost = 1;
        counter++;
        if(counter == 10 || i == neighborsListSize-1) {
            // Send LSP to each neighbor
            makePack(&routePack, TOS_NODE_ID, 0, 20, PROTOCOL_LINKSTATE, sequenceNum++, &linkStatePayload, sizeof(linkStatePayload));
            call Sender.send(routePack, AM_BROADCAST_ADDR);
            // Zero the array
            // for(j = 0; j < counter; j++){
            //     dbg(NEIGHBOR_CHANNEL, "%d %d\n", linkStatePayload[j].neighbor, linkStatePayload[j].cost);
            // }
            while(counter > 0) {
                counter--;
                linkStatePayload[i].neighbor = 0;
                linkStatePayload[i].cost = 0;
            }
        }
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