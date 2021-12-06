#include "../../includes/packet.h"
#include "../../includes/socket.h"
#include "../../includes/appPayload.h"

module AppP {
    provides interface App;
    uses interface Transport;
    uses interface LinkState;
    uses interface List<pack> as SeenList;
    uses interface SimpleSend as Sender;

}

implementation {
    pack sendPackage;
    uint16_t seqNum = 0;
    serverQueue users[50];
    socket_store_t searchFD(socket_t fd);
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, socket_store_t* payload, uint8_t length);
    bool ListContains(pack* packet);
    void logSocket(socket_store_t socket);

    command error_t App.bootControl(){
        uint16_t i;


        for(i = 0; i < 50; i++){
            users[i].username[0] = "\n";
            users[i].active = FALSE;
        }
        return SUCCESS;
    }

    command error_t App.connectClient(socket_t fd, socket_addr_t* addr){
        // dbg(TRANSPORT_CHANNEL, "I MADE IT HERE \n");
        socket_store_t socketFinder;

        socketFinder = searchFD(fd);

        if(socketFinder.fd < MAX_NUM_OF_SOCKETS){
            socketFinder.flag = APP_SYN_F;
            socketFinder.state = SYN_SENT;
            socketFinder.lastAck = 0;
            socketFinder.dest = *addr; // dest is 1
            makePack(&sendPackage, TOS_NODE_ID, socketFinder.dest.addr, 20, PROTOCOL_APP, seqNum, &(socketFinder), (uint8_t)sizeof(socketFinder));
            seqNum = seqNum + 1;
            call Transport.addSocket(socketFinder);
            call LinkState.computeSP(TOS_NODE_ID);
            call Sender.send(sendPackage, call LinkState.getNextHop(addr->addr));
            dbg(TRANSPORT_CHANNEL, "Client %d is trying to connect to server %d. SYN SENT TO %d\n", TOS_NODE_ID, sendPackage.dest, call LinkState.getNextHop(addr->addr));
            return SUCCESS;
        }
        // return FAIL;
    }

    command void App.receive(pack* packet){
        if(!ListContains(packet)){
            if(packet->dest != TOS_NODE_ID){
                call LinkState.computeSP(TOS_NODE_ID);
                makePack(&sendPackage, packet->src, packet->dest, packet->TTL - 1, packet->protocol, packet->seq, packet->payload, 20);
                dbg(TRANSPORT_CHANNEL, "Transport Packet Received at %d sending to %d\n", TOS_NODE_ID, call LinkState.getNextHop(packet->dest));
                call Sender.send(sendPackage, call LinkState.getNextHop(packet->dest));
            } else {
                userPack* payload;
                payload = (userPack*) packet->payload;

                if(payload->flag == LOGIN_F){
                    uint16_t i;
                    dbg(TRANSPORT_CHANNEL, "Received payload from user: %s", (char*)payload->payload);
                    for(i = 0; i < 20; i++){
                        users[packet->src].username[i] = payload->payload[i];
                        if(payload->payload[i+1] == '\n'){
                            break;
                        }
                    }
                    users[packet->src].active = TRUE;

                    dbg(TRANSPORT_CHANNEL, "Allocated: %s\n", users[packet->src].username);
                } else if (payload->flag == MESSAGE_F){
                    uint16_t i;
                    userPack broadcastMessage;
                    // dbg(TRANSPORT_CHANNEL, "FROM CLIENT: %s\n", users[packet->src].username);
                    broadcastMessage.flag = BROADCAST_F;
                    for(i = 0; i < 20; i++){
                        broadcastMessage.payload[i] = payload->payload[i];
                    }
                    for(i = 0; i < 50; i++){
                        if(users[i].active == TRUE){
                            makePack(&sendPackage, TOS_NODE_ID, i, 20, PROTOCOL_APP, seqNum, &(broadcastMessage), (uint8_t)sizeof(broadcastMessage));
                            seqNum = seqNum + 1;
                            call LinkState.computeSP(TOS_NODE_ID);
                            call Sender.send(sendPackage, call LinkState.getNextHop(sendPackage.dest));
                            dbg(TRANSPORT_CHANNEL, "Sending %s's message to %d\n", users[packet->src].username, sendPackage.dest);
                        }
                    }

                } else if (payload->flag == BROADCAST_F){
                    uint16_t i;
                    dbg(TRANSPORT_CHANNEL, "NEW MESSAGE: %s\n", payload->payload);
                } else if (payload->flag == PRIV_MESSAGE_F){
                    userPack sendMessage;
                    uint16_t i;
                    dbg(TRANSPORT_CHANNEL, "Received %d's Private message for Mote %d\n", packet->src, payload->destr);

                    sendMessage.flag = DELIVER_PRIV;
                    sendMessage.destr = payload->destr;
                    for(i = 0; i < 20; i++){
                        sendMessage.payload[i] = payload->payload[i];
                    }
                    makePack(&sendPackage, TOS_NODE_ID, payload->destr, 20, PROTOCOL_APP, seqNum, &(sendMessage), (uint8_t)sizeof(sendMessage));
                    seqNum = seqNum + 1;
                    call LinkState.computeSP(TOS_NODE_ID);
                    call Sender.send(sendPackage, call LinkState.getNextHop(sendPackage.dest));

                } else if (payload->flag == DELIVER_PRIV){
                    dbg(TRANSPORT_CHANNEL, "NEW PRIVATE MESSAGE: %s\n", payload->payload);
                } else if (payload->flag == REQUEST_USERS){
                    userPack response;
                    char* resp;
                    uint16_t i;
                    response.flag = RESPONSE_USERS;

                    resp = (char*)malloc(20);
                    for(i = 0; i < 50; i++){
                        if(users[i].active == TRUE){
                            strcat(resp, users[i].username);
                            strcat(resp, " ");
                        }
                    }
                    strcpy(response.payload, resp);
                    makePack(&sendPackage, TOS_NODE_ID, packet->src, 20, PROTOCOL_APP, seqNum++, &(response), (uint8_t)sizeof(response));
                    call LinkState.computeSP(TOS_NODE_ID);
                    call Sender.send(sendPackage, call LinkState.getNextHop(sendPackage.dest));
                } else if (payload->flag == RESPONSE_USERS){
                    dbg(TRANSPORT_CHANNEL, "SERVER RESPONSE, ONLINE USERS: %s\n", payload->payload);
                }

            }
        }
    }

    command void App.privateMessage(uint16_t dest, char* message){
        uint16_t i;
        userPack userMessage;



        for(i = 0; i < 20; i++){
            userMessage.payload[i] = message[i];
            if(message[i+1] == "\n") break;
        }
        userMessage.flag = PRIV_MESSAGE_F;
        userMessage.destr = dest;
        dbg(TRANSPORT_CHANNEL, "%d Sending %s\n", userMessage.destr, message);
        makePack(&sendPackage, TOS_NODE_ID, 1, 20, PROTOCOL_APP, seqNum, &(userMessage), (uint8_t)sizeof(userPack));
        memcpy(sendPackage.payload, &userMessage, (uint8_t) sizeof(userMessage));
        seqNum = seqNum + 1;
        call LinkState.computeSP(TOS_NODE_ID);
        call Sender.send(sendPackage, call LinkState.getNextHop(sendPackage.dest));

    }


    command void App.requestUsers(){
        uint16_t i;
        userPack userMessage;

        userMessage.flag = REQUEST_USERS;
        makePack(&sendPackage, TOS_NODE_ID, 1, 20, PROTOCOL_APP, seqNum, &(userMessage), (uint8_t)sizeof(userPack));
        memcpy(sendPackage.payload, &userMessage, (uint8_t) sizeof(userMessage));
        seqNum = seqNum + 1;
        call LinkState.computeSP(TOS_NODE_ID);
        call Sender.send(sendPackage, call LinkState.getNextHop(sendPackage.dest));
    }


    command void App.publicMessage(char* message){
        uint16_t i;
        userPack userMessage;

        dbg(TRANSPORT_CHANNEL, "Sending %s\n", message);
        userMessage.flag = MESSAGE_F;
        for(i = 0; i < 20; i++){
            userMessage.payload[i] = message[i];
            if(message[i+1] == "\n") break;
        }

        makePack(&sendPackage, TOS_NODE_ID, 1, 20, PROTOCOL_APP, seqNum, &(userMessage), (uint8_t)sizeof(userMessage));
        seqNum = seqNum + 1;
        call LinkState.computeSP(TOS_NODE_ID);
        call Sender.send(sendPackage, call LinkState.getNextHop(sendPackage.dest));


    }

    command void App.login(uint8_t fd, char* username){
        socket_store_t searchSocket;
        uint16_t i;
        userPack sendUser;
        sendUser.flag = LOGIN_F;
        for(i = 0; i < 20; i++){
            sendUser.payload[i] = username[i];
            if(username[i+1] == "\n")break;
        }
        searchSocket = searchFD(fd);
        makePack(&sendPackage, TOS_NODE_ID, searchSocket.dest.addr, 20, PROTOCOL_APP, seqNum, &(sendUser), (uint8_t)sizeof(sendUser));
        seqNum = seqNum + 1;
        call LinkState.computeSP(TOS_NODE_ID);
        call Transport.addSocket(searchSocket);
        call Sender.send(sendPackage, call LinkState.getNextHop(sendPackage.dest));

    }

    socket_store_t searchFD(socket_t fd){
        uint8_t i;
        socket_store_t lookingFD;
        socket_store_t emptyFD;
        // dbg(TRANSPORT_CHANNEL, "Size = %d\n", call SocketArr.size());
        for(i = 0; i < call Transport.getSocketSize(); i++){
            lookingFD = call Transport.getSocket(i);
            // dbg(TRANSPORT_CHANNEL, "%d\n", lookingFD.fd);
            if (lookingFD.fd == fd){
                call Transport.removeSocket(i);
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