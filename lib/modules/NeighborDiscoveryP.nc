#include "../../includes/packet.h"
#include "../../includes/protocol.h"
#include "../../includes/Neighbor.h"

module NeighborDiscoveryP{
    provides interface NeighborDiscovery;
    uses interface Timer<TMilli> as discoveryTimer;
    uses interface List<Neighbor*> as Neighbors;
    uses interface SimpleSend as Sender;
    uses interface List<pack> as SeenList;
    uses interface List<uint32_t> as NL;
    uses interface Flooding;
}

implementation {
    pack sendPack;
    uint16_t i;

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t *payload, uint8_t length);
    Neighbor* ListContains(pack* packet);

    command void NeighborDiscovery.bootTimer(){
        call discoveryTimer.startPeriodic( 10000 );
    }

    task void findNeighbors(){
        char* pingMessage;
        for(i = 0; i < call Neighbors.size(); i++){
            Neighbor* iter;
            iter = call Neighbors.get(i);
            iter->pingNumber++;
            // if(iter->pingNumber > 5) {
            //     iter->active = 0;
            // }
        }
        pingMessage = "findNeighbors(): Running\n";
        makePack(&sendPack, TOS_NODE_ID, AM_BROADCAST_ADDR, 2, PROTOCOL_PING, 1, (uint8_t*) pingMessage, (uint8_t) sizeof(pingMessage));
        call Flooding.addtoSeen(&sendPack);
        call Sender.send(sendPack, AM_BROADCAST_ADDR);
    }

    event void discoveryTimer.fired() {
        post findNeighbors();
    }

    command void NeighborDiscovery.routePings(pack* packet){
        Neighbor* foundNeighbor;
        if(packet->protocol == PROTOCOL_PING){
            makePack(&sendPack, TOS_NODE_ID, AM_BROADCAST_ADDR, packet->TTL - 1, PROTOCOL_PINGREPLY, packet->seq, (uint8_t *) packet->payload, PACKET_MAX_PAYLOAD_SIZE);
            call Flooding.addtoSeen(&sendPack);
            call Sender.send(sendPack, packet->src);
        } else if (packet->protocol == PROTOCOL_PINGREPLY){

            foundNeighbor = ListContains(packet);
            if(foundNeighbor->Node == 0){
                foundNeighbor->Node = packet->src;
                foundNeighbor->pingNumber = 0;
                foundNeighbor->active = 1;
                call Neighbors.pushback(foundNeighbor);
            } else {
                foundNeighbor->pingNumber = 0;
            }


        }
    }

    command uint32_t* NeighborDiscovery.printNeighbors(){ // Neighbor dump
        Neighbor* foundNeighbor;
        uint32_t ns[call Neighbors.size()];
        for(i = 0; i < call Neighbors.size(); i++){
            foundNeighbor = call Neighbors.get(i);
            if(foundNeighbor->active == 1){
                ns[i] = (uint32_t)foundNeighbor->Node;
                dbg(NEIGHBOR_CHANNEL, "NEIGHBOR: %d\n", ns[i]);
            }

        }
        return ns;
    }

    command uint16_t NeighborDiscovery.getNeighbors(){ // to be used in linkstate
        Neighbor* foundNeighbor;
        for(i = 0; i < call Neighbors.size(); i++){
            foundNeighbor = call Neighbors.get(i);
            if(foundNeighbor->active == 1){
                call NL.pushback(foundNeighbor->Node);

            }
        }
        return call NL.size();
    }

    command uint16_t NeighborDiscovery.getNeighbor(uint16_t i){
        return call NL.get(i);
    }

    command uint32_t NeighborDiscovery.neighborSize(){
        return call Neighbors.size();
    }

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
		Package->src = src;
		Package->dest = dest;
		Package->TTL = TTL;
		Package->seq = seq;
		Package->protocol = protocol;
		memcpy(Package->payload, payload, length);
	}

    Neighbor* ListContains(pack* packet){
		uint16_t i;
        Neighbor* empty;
		for(i = 0; i < call Neighbors.size(); i++){
			Neighbor* compare = call Neighbors.get(i);
			if(packet->src == compare->Node && compare->active == 1) return &compare;
            else if(packet->src == compare->Node){
                compare->active = 1;
                return &compare;
            }

		}
        empty = (Neighbor*) malloc(sizeof(Neighbor*));
        empty->Node = 0;
        empty->pingNumber = 0;
        empty->active = 0;
		return empty;
	}
}


// Create LSP timer
// Initialize routing table and linkstate array
// Send out LS Protocol packets



// FOR nodes receiving this packet:
    // if src == tos_node_id or already seen packet, drop it
    // else enter packet in packet seen
    // if state changes run dijkstra again
    // broadcast packet further