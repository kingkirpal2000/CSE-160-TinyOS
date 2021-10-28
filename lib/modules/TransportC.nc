configuration TransportC{
    provides interface Transport;
}

implementation {
    components TransportP;
    Transport = TransportP;

    components new ListC(socket_holder, MAX_NUM_OF_SOCKETS) as SA;
    TransportP.SocketArr -> SA;
}