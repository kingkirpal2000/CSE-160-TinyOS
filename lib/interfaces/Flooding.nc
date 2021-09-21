#include "../../includes/packet.h"

interface Flooding{
	command void ping(uint16_t destination, uint8_t *payload);
	command void relayFlood(pack* packet);
	command void addtoSeen(pack* packet);
}
