/**
 * @author UCM ANDES Lab
 * $Author: abeltran2 $
 * $LastChangedDate: 2014-08-31 16:06:26 -0700 (Sun, 31 Aug 2014) $
 *
 */


#include "../../CommandMsg.h"
#include "../../command.h"

module CommandHandlerC{
   provides interface CommandHandler;
}

implementation{

    command error_t CommandHandler.receive(CommandMsg *msg){
        uint8_t commandID;
        uint8_t* buff;


        dbg("cmdDebug", "A Command has been Issued.\n");
        buff = (uint8_t*) msg->payload;
        commandID = msg->id;

        //Find out which command was called and call related command
        switch(commandID){
            // A ping will have the destination of the packet as the first
            // value and the string in the remainder of the payload
            case CMD_PING:
                dbg("cmdDebug", "Command Type: Ping\n");
                signal CommandHandler.ping(buff[0], &buff[1]);
                return SUCCESS;

            case CMD_NEIGHBOR_DUMP:
                dbg("cmdDebug", "Command Type: Neighbor Dump\n");
                signal CommandHandler.printNeighbors();
                return SUCCESS;

            case CMD_LINKSTATE_DUMP:
                dbg("cmdDebug", "Command Type: Link State Dump\n");
                signal CommandHandler.printLinkState();
                return SUCCESS;

            case CMD_ROUTETABLE_DUMP:
                dbg("cmdDebug", "Command Type: Route Table Dump\n");
                signal CommandHandler.printRouteTable();
                return SUCCESS;

            case CMD_TEST_CLIENT:
                dbg("cmdDebug", "Command Type: Client\n");
                signal CommandHandler.setTestClient();
                return SUCCESS;

            case CMD_TEST_SERVER:
                dbg("cmdDebug", "Command Type: Client\n");
                signal CommandHandler.setTestServer();
                return SUCCESS;

            default:
                dbg("cmdDebug", "CMD_ERROR: \"%d\" does not match any known commands.\n", msg->id);
                return FAIL;
        }
    }
}
