/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"

module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface SimpleSend as Sender;
   uses interface Flooding;
   uses interface NeighborDiscovery;

   uses interface CommandHandler;
   uses interface LinkState;
   uses interface Transport;
}

implementation{
   pack sendPackage;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   event void Boot.booted(){
      call AMControl.start();
      call NeighborDiscovery.bootTimer();
      call LinkState.bootTimer();
      dbg(GENERAL_CHANNEL, "Booted\n");
   }

   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err){}

   // Whenever mote receives packet
   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      dbg(GENERAL_CHANNEL, "Packet Received\n");
      if(len==sizeof(pack)){
         pack* myMsg=(pack*) payload;
         // dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
         call Flooding.relayFlood(myMsg);
	      return msg;
      }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }

   // Whenever mote needs to send something
   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
      // uint16_t next = call LinkState.getNextHop(destination);
      // makePack(&sendPackage, TOS_NODE_ID, destination, 20, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      // call Sender.send(sendPackage, destination);
      // call Flooding.ping(destination, payload);
      call LinkState.ping(destination, payload);
   }

   event void CommandHandler.printNeighbors(){
      call NeighborDiscovery.printNeighbors();
   }

   event void CommandHandler.printRouteTable(){
      dbg(ROUTING_CHANNEL, "ACTIVATED\n");
      call LinkState.printRouteTable();
   }

   event void CommandHandler.printLinkState(){

   }

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(uint16_t port){}

   event void CommandHandler.setTestClient(uint16_t SRCP, uint16_t DP, uint16_t destination, uint8_t bufflen){
      socket_t s;
      socket_addr_t clientAddr;
      socket_addr_t serverAddr;
      s = call Transport.socket();
      clientAddr.addr = TOS_NODE_ID;
      clientAddr.port - SRCP;
      if (call Transport.bind(s, &clientAddr) == SUCCESS){
         serverAddr.addr = destination;
         serverAddr.port = DP;
         call Transport.connect(s, &serverAddr);
      }
   }

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
}
