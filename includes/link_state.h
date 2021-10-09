#ifndef LINK_STATE_H
#define LINK_STATE_H

#define numEntries 20
#define SENTINEL 250



typedef nx_struct lsMap{
    nx_uint8_t cost[numEntries];
}lsMap;


typedef nx_struct RoutingEntry{
    nx_uint16_t destination;
    nx_uint16_t nextHop;
    nx_uint16_t totalCost;
}RoutingEntry;

typedef nx_struct RoutingTable{
    RoutingEntry table[numEntries];
}RoutingTable;

#endif