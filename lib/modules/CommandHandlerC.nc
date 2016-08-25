/**
 * @author UCM ANDES Lab
 * $Author: abeltran2 $
 * $LastChangedDate: 2014-08-31 16:06:26 -0700 (Sun, 31 Aug 2014) $
 *
 */


#include "../../includes/CommandMsg.h"
#include "../../includes/command.h"
#include "../../includes/channels.h"

module CommandHandlerC{
   provides interface CommandHandler;
   uses interface Receive;
}

implementation{

    event message_t* Receive.receive(message_t* raw_msg, void* payload, uint8_t len){
        CommandMsg *msg;
        uint8_t commandID;
        uint8_t* buff;

        // Check to see if the packet is valid.
        if(len!=sizeof(CommandMsg) || !payload){
            // If it is invalid, return the value
            return raw_msg;
        }
        // Change it to our type.
        msg = (CommandMsg*) payload;

        dbg(COMMAND_CHANNEL, "A Command has been Issued.\n");
        buff = (uint8_t*) msg->payload;
        commandID = msg->id;

        //Find out which command was called and call related command
        switch(commandID){
            // A ping will have the destination of the packet as the first
            // value and the string in the remainder of the payload
            case CMD_PING:
                dbg(COMMAND_CHANNEL, "Command Type: Ping\n");
                signal CommandHandler.ping(buff[0], &buff[1]);
                break;

            case CMD_NEIGHBOR_DUMP:
                dbg(COMMAND_CHANNEL, "Command Type: Neighbor Dump\n");
                signal CommandHandler.printNeighbors();
                break;

            case CMD_LINKSTATE_DUMP:
                dbg(COMMAND_CHANNEL, "Command Type: Link State Dump\n");
                signal CommandHandler.printLinkState();
                break;

            case CMD_ROUTETABLE_DUMP:
                dbg(COMMAND_CHANNEL, "Command Type: Route Table Dump\n");
                signal CommandHandler.printRouteTable();
                break;

            case CMD_TEST_CLIENT:
                dbg(COMMAND_CHANNEL, "Command Type: Client\n");
                signal CommandHandler.setTestClient();
                break;

            case CMD_TEST_SERVER:
                dbg(COMMAND_CHANNEL, "Command Type: Client\n");
                signal CommandHandler.setTestServer();
                break;

            default:
                dbg(COMMAND_CHANNEL, "CMD_ERROR: \"%d\" does not match any known commands.\n", msg->id);
                break;
        }
        return raw_msg;
    }
}
