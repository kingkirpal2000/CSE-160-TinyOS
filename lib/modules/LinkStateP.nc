#include "../../includes/link_state.h"
#include "../../includes/route.h"
#include "../../includes/protocol.h"

module LinkStateP{
    provides interface LinkState;
    uses interface Timer<TMilli> as LStimer;
    uses interface NeighborDiscovery;
    uses interface SimpleSend as Sender;
    uses interface Random as Random;
    uses interface List<pack> as SeenList;
}

implementation {
pack sendPackage;
lsMap map[20];
uint16_t seqNum = 1;

void advertiseLSP();
void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length);
bool ListContains(pack* packet);

command void LinkState.bootTimer(){
     call LStimer.startOneShot(100000);
 }

event void LStimer.fired() {
    if(call LStimer.isOneShot()){
        call LStimer.startPeriodic(30000);
    } else {
        advertiseLSP();
    }
}

command void LinkState.handlePacket(pack* packet){
    uint16_t i;
    uint16_t j;
    if(!ListContains(packet)){
        if(TOS_NODE_ID != packet->src){
            for(i = 0; i < 20; i++){
                map[packet->src].cost[i] = 250;
            }
            for(i = 0; i < 20; i++){
                map[packet->src].cost[i] = packet->payload[i];
            }
            makePack(&sendPackage, packet->src, packet->dest, packet->TTL-1, packet->protocol, packet->seq, (uint8_t*) packet->payload, 20);
			call Sender.send(sendPackage, AM_BROADCAST_ADDR);
            for(i = 1; i < 20; i++){
                dbg(ROUTING_CHANNEL, "%d %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d \n", i, map[i].cost[1], map[i].cost[2], map[i].cost[3], map[i].cost[4], map[i].cost[5], map[i].cost[6], map[i].cost[7], map[i].cost[8], map[i].cost[9], map[i].cost[10], map[i].cost[11], map[i].cost[12]  );
            }

        }
    }
}


void advertiseLSP(){
    uint8_t i;
    uint8_t advertise[20];
    uint16_t NLsize;
    for(i = 0; i < 20; i++){
        advertise[i] = 250;
        map[TOS_NODE_ID].cost[i] = 250;
    }

    NLsize = call NeighborDiscovery.getNeighbors();
    for(i = 0; i < NLsize; i++){
        uint16_t n;

        n = call NeighborDiscovery.getNeighbor(i);
        map[TOS_NODE_ID].cost[n] = 1;
        advertise[n] = 1;
    }

        seqNum++;
        makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 20, PROTOCOL_LINKSTATE, seqNum, (uint8_t*)(advertise), 20);
        call Sender.send(sendPackage, AM_BROADCAST_ADDR);

}

bool ListContains(pack* packet){
    uint16_t i;
    for(i = 0; i < call SeenList.size(); i++){
        pack compare = call SeenList.get(i);
        if((packet->dest == compare.dest) && (packet->src == compare.src) && (packet->seq == compare.seq)) return TRUE;

    }
    call SeenList.pushfront(*packet);
	return FALSE;
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