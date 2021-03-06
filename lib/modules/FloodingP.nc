#include "../../includes/packet.h"
#include "../../includes/protocol.h"

module FloodingP{
	provides interface Flooding;
	uses interface SimpleSend as Sender;
	uses interface List<pack> as SeenList;
	uses interface NeighborDiscovery;
	uses interface LinkState;
}

implementation {
	pack sendPackage;
	// In tinyOS you must make prototypes of any Methods you create in module that isn't a command
	void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t *payload, uint8_t length);
	bool ListContains(pack* packet);
	uint16_t Node_Seq = 0;

	command void Flooding.ping(uint16_t destination, uint8_t *payload){ // Sending the message from a mote
		dbg(FLOODING_CHANNEL, "PINGING FROM FLOOD INTERFACE \n");
		// TOS_NODE_ID is global variable of the address of current mote
		makePack(&sendPackage, TOS_NODE_ID, destination, 20, PROTOCOL_PING, Node_Seq++, payload, PACKET_MAX_PAYLOAD_SIZE);
		call Sender.send(sendPackage, AM_BROADCAST_ADDR);
	}

	command void Flooding.relayFlood(pack* packet){

		if(ListContains(packet)){
			dbg(FLOODING_CHANNEL, "Already Seen Node... Dropping.... \n");
		} else if (packet->TTL == 0){
			dbg(FLOODING_CHANNEL, "TTL expired... Dropping .... \n");
		} else if (packet->dest == AM_BROADCAST_ADDR){
			// dbg(NEIGHBOR_CHANNEL, "Relay to NeighborDiscovery ACTIVATED \n");
			if(packet->protocol == PROTOCOL_LINKSTATE){
				call LinkState.handlePacket(packet);
			} else {
				call NeighborDiscovery.routePings(packet);
			}
		} else {
			call LinkState.handlePacket(packet);
		}

	}

	command void Flooding.addtoSeen(pack* packet){
		call SeenList.pushback(*packet);
	}

	void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
		Package->src = src;
		Package->dest = dest;
		Package->TTL = TTL;
		Package->seq = seq;
		Package->protocol = protocol;
		memcpy(Package->payload, payload, length);
	}

	bool ListContains(pack* packet){
		uint16_t i;
		for(i = 0; i < call SeenList.size(); i++){
			pack compare = call SeenList.get(i);
			if((packet->dest == compare.dest) && (packet->src == compare.src) && (packet->seq == compare.seq) && (packet->protocol == compare.protocol))return TRUE;

		}
		return FALSE;
	}
}

// Neighbor Discovery
	// Need to set a timer to periodically carry out task
	// Task to send out ping and expect a pingreply from dest node
	// Consider using HashmapC to hold neighbor table
