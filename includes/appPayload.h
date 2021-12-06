#ifndef __USER_H__
#define __USER_H__

enum user_flag {
    LOGIN_F = 1,
    MESSAGE_F = 2,
    PRIV_MESSAGE_F = 4,
    BROADCAST_F = 3,
    DELIVER_PRIV = 5,
    REQUEST_USERS = 6,
    RESPONSE_USERS = 7
};

typedef struct userPack{
    uint8_t flag;
    uint8_t destr;
    uint8_t payload[20];

}userPack;

typedef struct serverQueue{
    char username[50];
    bool active;
}serverQueue;

#endif