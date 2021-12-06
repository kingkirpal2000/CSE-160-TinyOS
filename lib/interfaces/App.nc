#include "../../includes/socket.h"
#include "../../includes/packet.h"

interface App{
   command error_t connectClient(socket_t fd, socket_addr_t* addr);
   command void receive(pack* packet);
   command void login(uint8_t fd, char* username);
   command error_t bootControl();
   command void publicMessage(char* message);
   command void privateMessage(uint16_t dest, char* message);
   command void requestUsers();
}
