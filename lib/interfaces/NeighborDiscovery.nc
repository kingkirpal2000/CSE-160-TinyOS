#include "../../includes/packet.h"

interface NeighborDiscovery{
	command void bootTimer();
	command void routePings(pack* packet);
	command void printNeighbors();
}
