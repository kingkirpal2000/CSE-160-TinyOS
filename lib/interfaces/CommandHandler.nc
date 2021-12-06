interface CommandHandler{
   // Events
   event void ping(uint16_t destination, uint8_t *payload);
   event void printNeighbors();
   event void printRouteTable();
   event void printLinkState();
   event void printDistanceVector();
   event void setTestServer(uint16_t port);
   event void setTestClient(uint16_t SRCP, uint16_t DP, uint16_t destination, uint8_t bufflen);
   event void setAppServer();
   event void setAppClient(char* username);
   event void TestClose(uint16_t dest, uint16_t destPort);
   event void message(char* message);
   event void unimessage(uint16_t dest, char* message);
   event void requestUsers();
}
