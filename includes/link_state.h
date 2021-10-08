#ifndef LINK_STATE_H
#define LINK_STATE_H

#define numEntries 20
#define SENTINEL -1



typedef nx_struct lsMap{
    nx_uint8_t cost[numEntries];
}lsMap;

#endif