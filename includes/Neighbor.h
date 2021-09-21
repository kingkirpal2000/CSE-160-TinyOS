#ifndef NEIGHBOR_H
#define NEIGHBOR_H

typedef nx_struct Neighbor{
    nx_uint16_t Node;
    nx_uint16_t pingNumber;
    nx_uint8_t active;
}Neighbor;

#endif