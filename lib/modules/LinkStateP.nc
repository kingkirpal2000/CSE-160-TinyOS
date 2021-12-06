#include "../../includes/link_state.h"
#include "../../includes/route.h"
#include "../../includes/protocol.h"

module LinkStateP{
    provides interface LinkState;
    uses interface Timer<TMilli> as LStimer;
    uses interface Timer<TMilli> as DTimer;
    uses interface NeighborDiscovery;
    uses interface SimpleSend as Sender;
    uses interface Random as Random;
    uses interface List<pack> as SeenList;
    uses interface Transport;
    uses interface App;
}

implementation {
pack sendPackage;
lsMap map[20];
uint16_t seqNum = 1;
RoutingEntry SP[100];
RoutingEntry computing[100];
uint16_t spCounter = 0;
uint16_t computingCounter = 0;

void advertiseLSP(); // advertise link state by flooding
void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length); // create packet
bool ListContains(pack* packet); // check if already seen packet
void popMinimum(RoutingEntry table[], uint16_t length, RoutingEntry sp[], uint16_t spLen); // dijkstra helper
void appendNode(RoutingEntry tableAppending[], RoutingEntry tableGarbage[], uint16_t* ap, uint16_t* gp); // dijkstra helper

command void LinkState.bootTimer(){
    // Used help from someone to come up with random interval
     call LStimer.startPeriodic(100000 + (uint16_t)((call Random.rand16())%200));
 }

event void LStimer.fired() {
    // Whenever timer fires, advertise packets using this method
    advertiseLSP();
}

event void DTimer.fired(){
    call LinkState.computeSP(TOS_NODE_ID); // radomly starts computing dijkstra so that it isn't waiting around
}

command void LinkState.ping(uint16_t destination, uint8_t *payload){
    dbg(ROUTING_CHANNEL, "PINGING FROM LINKSTATE INTERFACE\n");
    call LinkState.computeSP(TOS_NODE_ID); // Update shortest paths if any changes occured from the advertisement
    makePack(&sendPackage, TOS_NODE_ID, destination, 20, PROTOCOL_PING, seqNum++, payload, PACKET_MAX_PAYLOAD_SIZE);
    call Sender.send(sendPackage, call LinkState.getNextHop(destination));
}


command void LinkState.handlePacket(pack* packet){
    uint16_t i;
    uint16_t j;
    if(!ListContains(packet)){
        if(packet->protocol == PROTOCOL_LINKSTATE ){
            // If it is LinkState, it is in the advertisement phase of the protocol
            if(TOS_NODE_ID != packet->src){
                for(i = 0; i < 20; i++){
                    map[packet->src].cost[i] = 250; // initializes matrix row
                }
                for(i = 0; i < 20; i++){
                    map[packet->src].cost[i] = packet->payload[i]; // updates matrix row
                }
                // update TTL so advertisement packets dont circulate forever
                makePack(&sendPackage, packet->src, packet->dest, packet->TTL-1, packet->protocol, packet->seq, (uint8_t*) packet->payload, 20);
                call Sender.send(sendPackage, AM_BROADCAST_ADDR); // Broadcast
            }
        } else if (packet->protocol == PROTOCOL_PING){
            // This is a pinging packet, instead of flooding packets we need to compute the best path by computing dijkstra and asking for next hop
            if(packet->dest == TOS_NODE_ID){
                call LinkState.computeSP(TOS_NODE_ID); // Update shortest paths if any changes occured from the advertisement
                dbg(ROUTING_CHANNEL, "%d's message reached %d. PAYLOAD: %s\n", packet->src, packet->dest, packet->payload);
            } else {
                call LinkState.computeSP(TOS_NODE_ID); // Update shortest paths if any changes occured from the advertisement
                makePack(&sendPackage, packet->src, packet->dest, packet->TTL - 1, packet->protocol, packet->seq, packet->payload, PACKET_MAX_PAYLOAD_SIZE);
                // dbg(ROUTING_CHANNEL, "%d\n", call LinkState.getNextHop(packet->dest));
                call Sender.send(sendPackage, call LinkState.getNextHop(packet->dest)); // use get next hop to access Dijkstra answers
            }
        } else if (packet->protocol == PROTOCOL_TCP){
            call Transport.receive(packet);
        } else if (packet->protocol == PROTOCOL_APP){
            call App.receive(packet);
        }
    }
}

command uint16_t LinkState.getNextHop(uint16_t src){
    uint16_t i;
    for(i = 0; i < spCounter; i++){
        if(SP[i].destination == src){
            return SP[i].nextHop;
        }
    }
    return 255;
}

command void LinkState.printRouteTable(){
    uint16_t i;
    for(i = 0; i < spCounter; i++){
        dbg(TRANSPORT_CHANNEL, "Dest = %d NextHop = %d TotalCost = %d\n", SP[i].destination, SP[i].nextHop, SP[i].totalCost);
    }
}


void advertiseLSP(){
    // This method creates the initial link state packet which will be flooded
    // We flood this using the above LinkState.handlePacket() which is relayed by Flooding.relayFlood()
        // We simply made the distinction that this is a link state protocol packet and would like to be handled through LinkStateP.nc in FloodingP.nc
    // This advertise LSP is a preset row for TOS_NODE_ID which will be flooded to every lsMap map[] matrix
    // This lsMap map[] matrix is used as an adjacency matrix which is helpful to compute Dijkstras

    uint8_t i;
    uint8_t advertise[20];
    uint16_t NLsize;
    for(i = 0; i < 20; i++){
        advertise[i] = 250; // Creating the preset row
        map[TOS_NODE_ID].cost[i] = 250;
    }
    advertise[TOS_NODE_ID] = 0;
    map[TOS_NODE_ID].cost[TOS_NODE_ID] = 0;
    // We want all neighbors of TOS_NODE_ID to be 1 hop away and all the rest of the nodes we can calculate when we have full adjacency matrix
    NLsize = call NeighborDiscovery.getNeighbors();
    for(i = 0; i < NLsize; i++){
        uint16_t n;
        n = call NeighborDiscovery.getNeighbor(i);
        map[TOS_NODE_ID].cost[n] = 1; // Adding to its own map before it sends it out
        advertise[n] = 1; // adding to preset row
    }

        seqNum++;
        makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 20, PROTOCOL_LINKSTATE, seqNum, (uint8_t*)(advertise), 20);
        call Sender.send(sendPackage, AM_BROADCAST_ADDR);

}

command void LinkState.computeSP(uint8_t src){ // Dijkstra
    uint16_t i, j;

    RoutingEntry* init;
    init = (RoutingEntry*) malloc(sizeof(RoutingEntry));
    init->destination = src;
    init->nextHop = src;
    init->totalCost = 0;
    SP[spCounter++] = *init;

    // add remaining to computing
    for(i = 1; i < 20; i++){
        if(i != src){
            RoutingEntry* inAction;
            inAction = (RoutingEntry*) malloc(sizeof(RoutingEntry));
            inAction->destination = i;
            inAction->nextHop = i;
            inAction->totalCost = map[src].cost[i];
            computing[computingCounter++] = *inAction;
        }
    }
    while(computingCounter > 0){
        popMinimum(computing, computingCounter, SP, spCounter);
        computingCounter--;
        appendNode(SP, computing, &spCounter, &computingCounter);

    }


    for(i = 0; i < spCounter; i++){
            while(map[SP[i].nextHop].cost[src] != 1 && map[SP[i].nextHop].cost[src] != 0){
                for(j = 0; j < spCounter; j++){
                    if(SP[j].destination == SP[i].nextHop){
                        SP[i].nextHop = SP[j].nextHop;
                    }
                }
            }
    }


}

void appendNode(RoutingEntry tableAppending[], RoutingEntry tableGarbage[], uint16_t* ap, uint16_t* gp){
    // ONLY TO BE USED IN DIJKSTRA's COMPUTATION
    // append removed Node to done list
    tableAppending[*ap] = tableGarbage[*gp];
    *ap = *ap + 1;
}

void popMinimum(RoutingEntry table[], uint16_t length, RoutingEntry sp[], uint16_t spLen){
    // ONLY TO BE USED IN DIJKSTRA's COMPUTATION
    uint16_t i, j;
    uint16_t minimum = 255;
    uint16_t loc = 0;
    RoutingEntry temp;
    for(i = 0; i < length; i++){
        if(table[i].totalCost < minimum){
            minimum = table[i].totalCost;
            loc = i;
        }
    }
    temp = table[loc];
    table[loc] = table[length - 1];
    table[length - 1] = temp;

    // Go through all other nodes
    // if current cost > temp.totalCost + map[temp.destination].cost[current.destination]
        //  current.nexthop = temp.destination
        // current.totalCost =  map[temp.destination].cost[current.destination]

    for(i = 0; i < length-1; i++){
        if(table[i].totalCost > temp.totalCost + map[temp.destination].cost[table[i].destination]){
            table[i].totalCost = temp.totalCost + map[temp.destination].cost[table[i].destination];
            // to get the next hop you have to use temp->destination to look through SP
            // trying to find temp->destination, if that node's next hop is == temp->destination
            // other wise go behind one more some how
            table[i].nextHop = temp.destination;

        }
    }


    return;
}




bool ListContains(pack* packet){
    // Took almost the exact same method from FloodingP.nc
    uint16_t i;
    for(i = 0; i < call SeenList.size(); i++){
        pack compare = call SeenList.get(i);
        if((packet->dest == compare.dest) && (packet->src == compare.src) && (packet->seq == compare.seq) && (packet->protocol == compare.protocol)) return TRUE;

    }
    call SeenList.pushfront(*packet);
	return FALSE;
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




}