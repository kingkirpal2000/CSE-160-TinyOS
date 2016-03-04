/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 * 
 */ 

#include <Timer.h>

configuration NodeC{
}
implementation {
	components MainC;
	components Node;
	components new AMReceiverC(6);
	
   Node -> MainC.Boot;
	
   Node.Receive -> AMReceiverC;

   components ActiveMessageC;
	Node.AMControl -> ActiveMessageC;

   components SimpleSendC;
   Node.Sender -> SimpleSendC;

   components CommandHandlerC;
   Node.CommandHandler -> CommandHandlerC;
}
