#ifndef __CHANNELS_H__
#define __CHANNELS_H__

// These should really be const value, but the dbg command will spit out a ton
// of warnings.
char COMMAND_CHANNEL[]="command";
char GENERAL_CHANNEL[]="general";

char NEIGHBOR_CHANNEL[]="Project1N";
char FLOODING_CHANNEL[]="Project1F";

// Personal Debuggin Channels for some of the additional models implemented.
char HASHMAP_CHANNEL[]="hashmap";
#endif
