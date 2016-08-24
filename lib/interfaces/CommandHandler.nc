#include "../../CommandMsg.h"

interface CommandHandler{
   command error_t receive(CommandMsg *msg);


   // Events
   event void ping(uint8_t destination, uint8_t *payload);
   event void printNeighbors();
   event void printRouteTable();
   event void printLinkState();
   event void printDistanceVector();
   event void setTestServer();
   event void setTestClient();
   event void setAppServer();
   event void setAppClient();
}
