#include "../../includes/packet.h"

interface NeighborDiscovery{
	command void bootTimer();
	command void routePings(pack* packet);
	command uint32_t* printNeighbors();
	command uint32_t neighborSize();
	command uint16_t getNeighbors();
	command uint16_t getNeighbor(uint16_t i);
}
