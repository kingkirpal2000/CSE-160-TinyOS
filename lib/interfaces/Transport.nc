// #include "../../includes/packet.h"
#include "../../includes/socket.h"



interface Transport{
   command socket_t socket();
   command error_t bind(socket_t fd, socket_addr_t *addr);
   command socket_t accept(socket_t fd);
   command uint16_t write(socket_t fd, uint8_t *buff, uint16_t bufflen);
   command error_t receive(pack* package);
   command uint16_t read(socket_t fd, uint8_t *buff, uint16_t bufflen);
   command error_t connect(socket_t fd, socket_addr_t * addr);
   command error_t close(socket_t fd);
   command error_t release(socket_t fd);
   command error_t listen(socket_t fd);
   command void relayTCP(pack* packet);
}
