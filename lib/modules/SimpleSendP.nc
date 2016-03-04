/**
 * ANDES Lab - University of California, Merced
 * 
 * @author UCM ANDES Lab
 * @date   2013/09/03
 * 
 */
#include "../../packet.h"
#include "../../sendInfo.h"

module SimpleSendP{
   provides interface SimpleSend;

   uses interface Queue<sendInfo*>;
   uses interface Pool<sendInfo>;

   uses interface Timer<TMilli> as sendTimer;

   uses interface Packet;
   uses interface AMPacket;
   uses interface AMSend;

   uses interface Random;
}

implementation{
   uint16_t sequenceNum = 0;
   bool busy = FALSE;
   message_t pkt;

   error_t send(uint16_t src, uint16_t dest, pack *message);
   // A random element of delay is included to prevent congestion.
   void postSendTask(){
      if(call sendTimer.isRunning() == FALSE){
         call sendTimer.startOneShot( (call Random.rand16() %200) + 500);
      }
   }

   command error_t SimpleSend.send(pack msg, uint16_t dest) {
      if(!call Pool.empty()){
         sendInfo *input;

         input = call Pool.get();
         input->packet = msg;
         input->dest = dest;

         call Queue.enqueue(input);

         postSendTask();

         return SUCCESS;
      }
      return FAIL;
   }

   task void sendBufferTask(){
      if(!call Queue.empty() && !busy){
         sendInfo *info;
         info = call Queue.head();// Peak

         if(SUCCESS == send(info->src,info->dest, &(info->packet))){
            //Release resources used
            call Queue.dequeue();
            call Pool.put(info);
         }


      }
      if(!call Queue.empty()){
         postSendTask();
      }
   }

   event void sendTimer.fired(){
      post sendBufferTask();
   }

   /*
    * Send a packet
    *
    *@param
    *	src - source address
    *	dest - destination address
    *	msg - payload to be sent
    *
    *@return
    *	error_t - Returns SUCCESS, EBUSY when the system is too busy using the radio, or FAIL.
    */
   error_t send(uint16_t src, uint16_t dest, pack *message){
      if(!busy){
         pack* msg = (pack *)(call Packet.getPayload(&pkt, sizeof(pack) ));			
         *msg = *message;

         if(call AMSend.send(dest, &pkt, sizeof(pack)) ==SUCCESS){
            busy = TRUE;
            return SUCCESS;
         }else{
            dbg("genDebug","The radio is busy, or something\n");
            return FAIL;
         }
      }else{
         dbg("genDebug", "The radio is busy");
         return EBUSY;
      }
      dbg("genDebug", "FAILED!?");
      return FAIL;
   }	

   event void AMSend.sendDone(message_t* msg, error_t error){
      //Clear Flag, we can send again.
      if(&pkt == msg){
         busy = FALSE;
         postSendTask();
      }
   }
}
