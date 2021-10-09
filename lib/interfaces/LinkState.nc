interface LinkState{
	command void bootTimer();
	command void handlePacket(pack* packet);
}