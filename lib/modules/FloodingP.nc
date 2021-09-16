#include "../../includes/packet.h"
#include "../../includes/protocol.h"

module FloodingP{
	provides interface Flooding;
	uses interface SimpleSend as Sender;
	uses interface Hashmap<uint16_t> as SeenList;
}

implementation {
	pack sendPackage;

	void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t *payload, uint8_t length);

	command void Flooding.ping(uint16_t destination, uint8_t *payload){
		// Make a package and send it using flooding system
		dbg(FLOODING_CHANNEL, "PINGING FROM FLOOD INTERFACE \n");
		// Don't know what goes in seq parameter for now just trying to send packets for now
		// Might be to keep track of flood number
		makePack(&sendPackage, TOS_NODE_ID, destination, 20, PROTOCOL_PING, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
		call Sender.send(sendPackage, destination);
	}

	command void Flooding.relayFlood(pack* packet){
		// Send off package if this isn't destination or handle packet if it is
		// Check if you already seen before
		// Check if TTL is less than 0
		// Check if this is destination
		// Send it off to its nearest neighbor
		dbg(FLOODING_CHANNEL, "printing Seenlist 1 \n");
		call SeenList.insert(1, 5);
		dbg(FLOODING_CHANNEL, "FIRST KEY IS %d\n", call SeenList.get(1));

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
