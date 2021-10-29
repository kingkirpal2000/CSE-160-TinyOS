#include "../../includes/packet.h"
#include "../../includes/socket.h"

module TransportP{
    provides interface Transport;
    uses interface LinkState;
    uses interface SimpleSend as Sender;
    uses interface List<socket_holder> as SocketArr;
    uses interface List<pack> as SeenList;
}

implementation {
    socket_holder searchFD(socket_t fd);
    bool ListContains(pack* packet);
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length); // create packet


    socket_store_t socketList[MAX_NUM_OF_SOCKETS];
    uint8_t socketIterator = 0;
    uint16_t seqNum = 1;
    pack sendPackage;
    /**
    * Get a socket if there is one available.
    * @Side Client/Server
    * @return
    *    socket_t - return a socket file descriptor which is a number
    *    associated with a socket. If you are unable to allocated
    *    a socket then return a NULL socket_t.
    */
    command socket_t Transport.socket() {
        socket_holder allocateFD;
        if(call SocketArr.size() < MAX_NUM_OF_SOCKETS){
            allocateFD.fd = (socket_t) call SocketArr.size();
            allocateFD.state.lastWritten = 0;
            allocateFD.state.effectiveWindow = SOCKET_BUFFER_SIZE;
            call SocketArr.pushback(allocateFD);
            dbg(TRANSPORT_CHANNEL, "%d\n", allocateFD.fd);
            return allocateFD.fd;
        }
    }

   /**
    * Bind a socket with an address.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       you are binding.
    * @param
    *    socket_addr_t *addr: the source port and source address that
    *       you are biding to the socket, fd.
    * @Side Client/Server
    * @return error_t - SUCCESS if you were able to bind this socket, FAIL
    *       if you were unable to bind.
    */
   command error_t Transport.bind(socket_t fd, socket_addr_t *addr){
       socket_holder foundFD;
       foundFD = searchFD(fd);

       if(foundFD.fd == 255){
           return FAIL;
       } else {
           foundFD.state.src = addr->port;
           foundFD.state.dest = *addr;
           dbg(TRANSPORT_CHANNEL, "Successfully bounded to socket: %d\n", fd);
           return SUCCESS;
       }

   }

   /**
    * Checks to see if there are socket connections to connect to and
    * if there is one, connect to it.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that is attempting an accept. remember, only do on listen.
    * @side Server
    * @return socket_t - returns a new socket if the connection is
    *    accepted. this socket is a copy of the server socket but with
    *    a destination associated with the destination address and port.
    *    if not return a null socket.
    */
   command socket_t Transport.accept(socket_t fd){
       dbg(GENERAL_CHANNEL, "Filler\n");
   }

   /**
    * Write to the socket from a buffer. This data will eventually be
    * transmitted through your TCP implimentation.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that is attempting a write.
    * @param
    *    uint8_t *buff: the buffer data that you are going to wrte from.
    * @param
    *    uint16_t bufflen: The amount of data that you are trying to
    *       submit.
    * @Side For your project, only client side. This could be both though.
    * @return uint16_t - return the amount of data you are able to write
    *    from the pass buffer. This may be shorter then bufflen
    */
   command uint16_t Transport.write(socket_t fd, uint8_t *buff, uint16_t bufflen){
       dbg(GENERAL_CHANNEL, "Filler\n");
   }

   /**
    * This will pass the packet so you can handle it internally.
    * @param
    *    pack *package: the TCP packet that you are handling.
    * @Side Client/Server
    * @return uint16_t - return SUCCESS if you are able to handle this
    *    packet or FAIL if there are errors.
    */
   command error_t Transport.receive(pack* package){
       dbg(GENERAL_CHANNEL, "Filler\n");
   }

   /**
    * Read from the socket and write this data to the buffer. This data
    * is obtained from your TCP implimentation.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that is attempting a read.
    * @param
    *    uint8_t *buff: the buffer that is being written.
    * @param
    *    uint16_t bufflen: the amount of data that can be written to the
    *       buffer.
    * @Side For your project, only server side. This could be both though.
    * @return uint16_t - return the amount of data you are able to read
    *    from the pass buffer. This may be shorter then bufflen
    */
   command uint16_t Transport.read(socket_t fd, uint8_t *buff, uint16_t bufflen){
       dbg(GENERAL_CHANNEL, "Filler\n");
   }

   /**
    * Attempts a connection to an address.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that you are attempting a connection with.
    * @param
    *    socket_addr_t *addr: the destination address and port where
    *       you will atempt a connection.
    * @side Client
    * @return socket_t - returns SUCCESS if you are able to attempt
    *    a connection with the fd passed, else return FAIL.
    */
   command error_t Transport.connect(socket_t fd, socket_addr_t * addr){
        // Start of three way handshake
        pack SYN;
        socket_holder socketFinder;
        socket_holder temp;
        uint8_t nHop; // next hop
        socketFinder = searchFD(fd);

        if(socketFinder.fd < MAX_NUM_OF_SOCKETS && nHop != 255){
            socketFinder.state.flag = 1;
            socketFinder.state.state = SYN_SENT;
            socketFinder.state.src = addr->port;
            socketFinder.state.dest = *addr;
            makePack(&SYN, TOS_NODE_ID, addr->addr, 20, PROTOCOL_TCP, 1, &(socketFinder.state), (uint8_t)sizeof(socketFinder.state));
            call SocketArr.pushback(socketFinder);
            dbg(TRANSPORT_CHANNEL, "%d\n", call LinkState.getNextHop(addr->addr));
            call Sender.send(SYN, call LinkState.getNextHop(addr->addr));
            return SUCCESS;
        } else {
            return FAIL;
        }

   }

   /**
    * Closes the socket.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that you are closing.
    * @side Client/Server
    * @return socket_t - returns SUCCESS if you are able to attempt
    *    a closure with the fd passed, else return FAIL.
    */
   command error_t Transport.close(socket_t fd){
       dbg(GENERAL_CHANNEL, "Filler\n");

   }

   /**
    * A hard close, which is not graceful. This portion is optional.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that you are hard closing.
    * @side Client/Server
    * @return socket_t - returns SUCCESS if you are able to attempt
    *    a closure with the fd passed, else return FAIL.
    */
   command error_t Transport.release(socket_t fd){
       dbg(GENERAL_CHANNEL, "Filler\n");
   }

    /**
    * Listen to the socket and wait for a connection.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that you are hard closing.
    * @side Server
    * @return error_t - returns SUCCESS if you are able change the state
    *   to listen else FAIL.
    */
    command error_t Transport.listen(socket_t fd){
        dbg(GENERAL_CHANNEL, "Filler\n");
    }

    command void Transport.relayTCP(pack* packet){
        dbg(TRANSPORT_CHANNEL, "HERHERHEHE\n");
        if(!ListContains(packet)){
            if(packet->dest != TOS_NODE_ID){
                call LinkState.computeSP(TOS_NODE_ID);
                makePack(&sendPackage, packet->src, packet->dest, packet->TTL - 1, packet->protocol, packet->seq, (uint8_t*) packet->payload, 20);
                dbg(TRANSPORT_CHANNEL, "Transport Packet Received at %d sending to %d\n", TOS_NODE_ID, call LinkState.getNextHop(packet->dest));
                call Sender.send(sendPackage, call LinkState.getNextHop(packet->dest));
            }
        }
    }

    socket_holder searchFD(socket_t fd){
        uint8_t i;
        socket_holder lookingFD;
        socket_holder emptyFD;
        for(i = 0; i < call SocketArr.size(); i++){
            lookingFD = call SocketArr.get(i);
            if (lookingFD.fd == fd){
                // call SocketArr.remove(i);
                return lookingFD;
            }
        }
        emptyFD.fd = 255;
        return emptyFD;
    }
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
        // Given to us in skeleton code
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }

    bool ListContains(pack* packet){
    // Took almost the exact same method from FloodingP.nc
    uint16_t i;
    for(i = 0; i < call SeenList.size(); i++){
        pack compare = call SeenList.get(i);
        if((packet->dest == compare.dest) && (packet->src == compare.src) && (packet->seq == compare.seq)) return TRUE;

    }
    call SeenList.pushfront(*packet);
	return FALSE;
}

}