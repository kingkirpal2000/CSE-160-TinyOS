#include "../../includes/packet.h"
#include "../../includes/socket.h"

module TransportP{
    provides interface Transport;
    uses interface LinkState;
    uses interface SimpleSend as Sender;
    uses interface List<socket_store_t> as SocketArr;
    uses interface List<pack> as SeenList;
    uses interface List<pack> as pktQueue;
    uses interface Timer<TMilli> as timer;
}

implementation {
    socket_store_t searchFD(socket_t fd);
    bool ListContains(pack* packet);
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, socket_store_t* payload, uint8_t length); // create packet
    void logSocket(socket_store_t socket);

    socket_store_t socketList[MAX_NUM_OF_SOCKETS];
    uint8_t socketIterator = 0;
    uint16_t seqNum = 1;
    pack sendPackage;
    uint16_t nextHop = 0;
    /**
    * Get a socket if there is one available.
    * @Side Client/Server
    * @return
    *    socket_t - return a socket file descriptor which is a number
    *    associated with a socket. If you are unable to allocated
    *    a socket then return a NULL socket_t.
    */
    command socket_t Transport.socket() {
        socket_store_t allocateFD;
        if(call SocketArr.size() < MAX_NUM_OF_SOCKETS){
            allocateFD.fd = (socket_t) call SocketArr.size();
            allocateFD.lastWritten = 0;
            allocateFD.effectiveWindow = SOCKET_BUFFER_SIZE;
            call SocketArr.pushback(allocateFD);
            return allocateFD.fd;
        }
        else return 255;
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
       socket_store_t foundFD;
       foundFD = searchFD(fd);

       if(foundFD.fd == 255){
           return FAIL;
       } else {
           foundFD.src = addr->port;
           foundFD.dest = *addr;
           dbg(TRANSPORT_CHANNEL, "Successfully bound to socket: %d\n", fd);
           call SocketArr.pushback(foundFD);
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
        socket_store_t* findSocket;
        socket_store_t temp;
        socket_store_t* a;
        uint16_t i;
        uint16_t bufferIT = 0;
        // findSocket = searchFD(fd);
        // a = (socket_store_t*)malloc(sizeof(socket_store_t));
        findSocket = (socket_store_t*)malloc(sizeof(socket_store_t));
        for(i = 0; i < call SocketArr.size(); i++){
            temp = call SocketArr.get(i);
            if(temp.fd == fd){
                temp = call SocketArr.remove(i);
                *findSocket = temp;
            }
        }

        logSocket(*findSocket);
        if(findSocket->lastWritten + bufflen >= SOCKET_BUFFER_SIZE){
            findSocket->lastWritten = 0;
        }
        for(i = findSocket->lastWritten; i < bufflen; i++){
            findSocket->sendBuff[i] = buff[bufferIT++];
            dbg(TRANSPORT_CHANNEL, "%d WRITING: %d\n", i, findSocket->sendBuff[i]);
        }

        findSocket->lastWritten = i;
        findSocket->flag = DATA_PACK_F;
        logSocket(*findSocket);
        dbg(TRANSPORT_CHANNEL, "%d\n", findSocket->lastWritten);
        makePack(&sendPackage, TOS_NODE_ID, findSocket->dest.addr, 20, PROTOCOL_TCP, seqNum++, findSocket, sizeof(*findSocket));
        // sendPackage.src = TOS_NODE_ID;
        // sendPackage.dest = findSocket->dest.addr;
        // sendPackage.TTL = 20;
        // sendPackage.protocol = PROTOCOL_TCP;
        // sendPackage.seq = seqNum++;
        // memcpy(&sendPackage.payload, findSocket, sizeof(socket_store_t));
        // a = (socket_store_t*)packet->payload;


        a = (socket_store_t*)sendPackage.payload;
        for(i = 0; i < 6; i++){
            dbg(TRANSPORT_CHANNEL, "%d RE-WRITING: %d\n", a->lastRead, a->sendBuff[i]);
        }
        call LinkState.computeSP(TOS_NODE_ID);
        dbg(TRANSPORT_CHANNEL, "Sending written buffer from %d to %d next hop: %d\n", TOS_NODE_ID, sendPackage.dest, call LinkState.getNextHop(sendPackage.dest));
        call Sender.send(sendPackage, call LinkState.getNextHop(sendPackage.dest));
        call pktQueue.pushback(sendPackage);
        call timer.startOneShot(140000);
        call SocketArr.pushback(*findSocket);

   }

   /**
    * This will pass the packet so you can handle it internally.
    * @param
    *    pack *package: the TCP packet that you are handling.
    * @Side Client/Server
    * @return uint16_t - return SUCCESS if you are able to handle this
    *    packet or FAIL if there are errors.
    */
   command error_t Transport.receive(pack* packet){

       if(!ListContains(packet)){

            if(packet->dest != TOS_NODE_ID){
                call LinkState.computeSP(TOS_NODE_ID);
                makePack(&sendPackage, packet->src, packet->dest, packet->TTL - 1, packet->protocol, packet->seq, packet->payload, 20);
                dbg(TRANSPORT_CHANNEL, "Transport Packet Received at %d sending to %d\n", TOS_NODE_ID, call LinkState.getNextHop(packet->dest));
                call Sender.send(sendPackage, call LinkState.getNextHop(packet->dest));
            } else { // this is wrong
                socket_store_t* payload;
                socket_store_t findSocket;
                socket_store_t temp;
                uint16_t i;
                payload = (socket_store_t*)malloc(sizeof(socket_store_t));
                payload = packet->payload;

                    if(payload->flag == SYN_F) {
                        for(i = 0; i < call SocketArr.size(); i++){
                            temp = call SocketArr.get(i);
                            if(temp.src == payload->dest.port && temp.state == LISTEN){
                                temp = call SocketArr.remove(i);
                                findSocket = temp;
                            }
                        }
                        dbg(TRANSPORT_CHANNEL, "Connecting socket %d\n", findSocket.fd);
                        findSocket.flag = SYN_ACK_F;
                        findSocket.dest.port = payload->src;
                        findSocket.dest.addr = packet->src;
                        findSocket.state = SYN_RCVD;

                        logSocket(findSocket);
                        call SocketArr.pushback(findSocket);

                        makePack(&sendPackage, TOS_NODE_ID, packet->src, 20, PROTOCOL_TCP, seqNum++ , &(findSocket), (uint8_t)sizeof(findSocket));
                        dbg(TRANSPORT_CHANNEL, "SYN packet from %d HANDLED replying with SYN_ACK to %d \n", sendPackage.src, sendPackage.dest);
                        call LinkState.computeSP(TOS_NODE_ID);
                        call Sender.send(sendPackage, call LinkState.getNextHop(sendPackage.dest));
                        return SUCCESS;
                    } else if (payload->flag == SYN_ACK_F) {
                        for(i = 0; i < call SocketArr.size(); i++){
                            temp = call SocketArr.get(i);
                            if(temp.dest.port == payload->src && temp.src == payload->dest.port){
                                temp = call SocketArr.remove(i);
                                findSocket = temp;
                            }
                        }
                        dbg(TRANSPORT_CHANNEL, "Connecting socket %d\n", findSocket.fd);
                        findSocket.flag = SYN_EST_F;
                        findSocket.dest.port = payload->src;
                        findSocket.dest.addr = packet->src;
                        findSocket.state = ESTABLISHED;
                        // call SocketArr.pushback(findSocket);
                        call SocketArr.pushback(findSocket);
                        makePack(&sendPackage, TOS_NODE_ID, packet->src, 20, PROTOCOL_TCP, seqNum++, &(findSocket), (uint8_t)sizeof(findSocket));
                        call LinkState.computeSP(TOS_NODE_ID);
                        call Sender.send(sendPackage, call LinkState.getNextHop(sendPackage.dest));
                        dbg(TRANSPORT_CHANNEL, "SYN_ACK packet from %d HANDLED replying with SYN_EST_F to %d \n", sendPackage.src, sendPackage.dest);
                        logSocket(findSocket);
                        return SUCCESS;
                    } else if (payload->flag == SYN_EST_F){
                        uint8_t buffer[SOCKET_BUFFER_SIZE];
                        uint16_t j;
                        socket_store_t garbage;
                        dbg(TRANSPORT_CHANNEL, "THREE WAY HANDSHAKE COMPLETED\n");
                        for(i = 0; i < call SocketArr.size(); i++){
                            temp = call SocketArr.get(i);
                            if(temp.dest.port == payload->src && temp.src == payload->dest.port){
                                dbg(TRANSPORT_CHANNEL, "DSLFJSDLFJSLDFJLS\n");
                                // temp = call SocketArr.remove(i);
                                findSocket = temp;
                                logSocket(findSocket);
                            }
                        }

                        for(j = 0; j < 6; j++){
                            buffer[j] = j;
                        }


                        findSocket.state = ESTABLISHED;
                        call Transport.write(findSocket.fd, buffer, 6);


                        // dbg(TRANSPORT_CHANNEL, "%d\n", call SocketArr.size());
                        // garbage = searchFD(findSocket.fd);
                        //  dbg(TRANSPORT_CHANNEL, "%d\n", call SocketArr.size());
                        // call SocketArr.pushback(findSocket);
                        return SUCCESS;
                    } else if (payload->flag == DATA_PACK_F){
                        socket_store_t* t;
                        socket_store_t findSocket;
                        t = (socket_store_t*)malloc(sizeof(socket_store_t) + SOCKET_BUFFER_SIZE);
                        t = packet->payload;
                        // findSocket = searchFD(0); // hardcoded 0 should be t->fd

                        call Transport.read(t->fd, t->sendBuff, 6);
                    } else if (payload->flag == DATA_ACK_F){
                        call pktQueue.popfront();

                    } else if (payload->flag == FIN_WAIT_F){
                        findSocket.flag = FIN_ACK_F;
                        findSocket.state = CLOSED;
                        makePack(&sendPackage, TOS_NODE_ID, packet->src, 20, PROTOCOL_TCP, seqNum++, &(findSocket), (uint8_t)sizeof(findSocket));
                        call LinkState.computeSP(TOS_NODE_ID);
                        call Sender.send(sendPackage, call LinkState.getNextHop(sendPackage.dest));
                    } else if (payload->flag == FIN_ACK_F){
                        findSocket.state = CLOSED;
                        findSocket.flag = 0;
                        dbg(TRANSPORT_CHANNEL, "TEARDOWN COMPLETE BETWEEN NODES %d and %d\n", packet->src, packet->dest);
                    }






            }
        }
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
        uint16_t i;
        uint16_t read;
        socket_store_t findSocket;
        socket_store_t temp;

        findSocket = searchFD(fd);
        findSocket.lastRead = 0;
        if(findSocket.lastRead == SOCKET_BUFFER_SIZE){
            findSocket.lastRead = 0;
        }
        for( i = 0; i < bufflen; i++){
            findSocket.rcvdBuff[findSocket.lastRead + i] = buff[i];
            dbg(TRANSPORT_CHANNEL, "DATA READING: %d\n", buff[i]);
            if((findSocket.lastRead + i) >= SOCKET_BUFFER_SIZE) {
                read = (i - findSocket.lastRead);
                findSocket.lastRead = SOCKET_BUFFER_SIZE;
                dbg(TRANSPORT_CHANNEL, "Data was read onto Socket %d\n", fd);
                call SocketArr.pushback(findSocket);
                return read;
            }

        }
        read = i - findSocket.lastRead;
        findSocket.lastRead = findSocket.lastRead + i;
        findSocket.nextExpected = findSocket.lastRead + 1;
        findSocket.flag = DATA_ACK_F;
        temp.flag = DATA_ACK_F;
        dbg(TRANSPORT_CHANNEL, "Data was read onto Socket %d READ= %d\n", fd, read);

        makePack(&sendPackage, TOS_NODE_ID, findSocket.dest.addr, 20, PROTOCOL_TCP, seqNum++, &(findSocket), (uint8_t)sizeof(findSocket) + SOCKET_BUFFER_SIZE);
        call LinkState.computeSP(TOS_NODE_ID);
        dbg(TRANSPORT_CHANNEL, "%d\n", call LinkState.getNextHop(sendPackage.dest));
        call Sender.send(sendPackage, call LinkState.getNextHop(sendPackage.dest));
        call SocketArr.pushback(findSocket);
        return read;
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
        socket_store_t socketFinder;
        socket_store_t temp;
        uint8_t nHop; // next hop
        socketFinder = searchFD(fd);
        if(socketFinder.fd < MAX_NUM_OF_SOCKETS){
            socketFinder.flag = SYN_F;
            socketFinder.state = SYN_SENT;
            socketFinder.lastAck = 0;
            // socketFinder.src = addr->port;
            socketFinder.dest = *addr;
            logSocket(socketFinder);
            makePack(&SYN, TOS_NODE_ID, addr->addr, 20, PROTOCOL_TCP, seqNum++, &(socketFinder), (uint8_t)sizeof(socketFinder));
            call SocketArr.pushback(socketFinder);
            call LinkState.computeSP(TOS_NODE_ID);
            call Sender.send(SYN, call LinkState.getNextHop(addr->addr));
            // dbg(TRANSPORT_CHANNEL, "Socket fd: %d, src: %d dest: %d \n", socketFinder.fd, socketFinder.src, socketFinder.dest.addr);
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
        socket_store_t findingSocket;
        findingSocket = searchFD(fd);

        // dbg(TRANSPORT_CHANNEL, "Source is %d and dest is %d\n", findingSocket.dest.port, findingSocket.dest.addr);
        findingSocket.flag = FIN_WAIT_F;
        findingSocket.state = FIN_SENT;
        call SocketArr.pushback(findingSocket);
        makePack(&sendPackage, TOS_NODE_ID, findingSocket.dest.addr, 20, PROTOCOL_TCP, seqNum++, &(findingSocket), (uint16_t)sizeof(findingSocket));

        dbg(TRANSPORT_CHANNEL, "Sending FIN pack to %d\n", call LinkState.getNextHop(sendPackage.dest));
        call LinkState.computeSP(TOS_NODE_ID);
        call Sender.send(sendPackage, call LinkState.getNextHop(sendPackage.dest));
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
        socket_store_t socket;

        socket = searchFD(fd);
        socket.state = LISTEN;
        dbg(TRANSPORT_CHANNEL, "Socket %d is now listening... \n", fd);
        call SocketArr.pushback(socket);
        return SUCCESS;
    }

    command socket_store_t Transport.searchSocket(uint16_t dest, uint16_t destPort){
        uint16_t i;
        socket_store_t lookingFD;
        socket_store_t emptyFD;
        for(i = 0; i < call SocketArr.size(); i++){
            lookingFD = call SocketArr.get(i);
            if(lookingFD.dest.port == destPort && lookingFD.dest.addr == dest){
                // call SocketArr.remove(i);
                return lookingFD;
            }
        }
        emptyFD.fd = 255;
        return emptyFD;
    }

    event void timer.fired(){
        // pack p = call pktQueue.get(0);
        pack top = call pktQueue.popfront();
        makePack(&sendPackage, TOS_NODE_ID, top.dest, 20, PROTOCOL_TCP, ++seqNum, top.payload, 28);
        call Sender.send(sendPackage, sendPackage.dest);

    }

    socket_store_t searchFD(socket_t fd){
        uint8_t i;
        socket_store_t lookingFD;
        socket_store_t emptyFD;
        // dbg(TRANSPORT_CHANNEL, "Size = %d\n", call SocketArr.size());
        for(i = 0; i < call SocketArr.size(); i++){
            lookingFD = call SocketArr.get(i);
            // dbg(TRANSPORT_CHANNEL, "%d\n", lookingFD.fd);
            if (lookingFD.fd == fd){
                call SocketArr.remove(i);
                return lookingFD;
            }
        }
        emptyFD.fd = 255;
        return emptyFD;
    }
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, socket_store_t* payload, uint8_t length){
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

    void logSocket(socket_store_t socket){
        dbg(TRANSPORT_CHANNEL, "FD: %d, flag: %d, src: %d, dest address: %d, dest port: %d\n", socket.fd, socket.flag, socket.src, socket.dest.addr, socket.dest.port);
    }

}