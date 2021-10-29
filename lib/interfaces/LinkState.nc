interface LinkState{
	command void bootTimer();
	command void handlePacket(pack* packet);
	command uint16_t getNextHop(uint16_t src);
	command void ping(uint16_t destination, uint8_t *payload);
	command void printRouteTable();
	command void computeSP(uint8_t src); // dijkstra

}