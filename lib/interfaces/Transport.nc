// #include "../../includes/packet.h"
#include "../../includes/socket.h"



interface Transport{
   command socket_t socket();
   command error_t bind(socket_t fd, socket_addr_t *addr);
   command socket_t accept(socket_t fd);
   command uint16_t write(socket_t fd, uint8_t *buff, uint16_t bufflen);
   command error_t receive(pack* package);
   command uint16_t read(socket_t fd, uint8_t *buff, uint16_t bufflen);
   command error_t connect(socket_t fd, socket_addr_t * addr, char* username);
   command error_t close(socket_t fd);
   command error_t release(socket_t fd);
   command error_t listen(socket_t fd);
   command socket_store_t searchSocket(uint16_t dest, uint16_t destPort);
   command uint16_t getSocketSize();
   command socket_store_t getSocket(uint16_t in);
   command socket_store_t removeSocket(uint16_t in);
   command void addSocket(socket_store_t sock);
}
