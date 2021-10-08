#include "../../includes/packet.h"

interface NeighborDiscovery{
	command void bootTimer();
	command void routePings(pack* packet);
	command uint32_t* printNeighbors();
	command uint32_t neighborSize();
}
