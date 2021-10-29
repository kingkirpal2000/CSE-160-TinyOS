configuration TransportC{
    provides interface Transport;
}

implementation {
    components TransportP;
    Transport = TransportP;

    components new ListC(socket_store_t, MAX_NUM_OF_SOCKETS) as SA;
    TransportP.SocketArr -> SA;

    components LinkStateC;
    TransportP.LinkState -> LinkStateC;

	components new SimpleSendC(AM_PACK);
	TransportP.Sender -> SimpleSendC;

    components new ListC(pack, 100) as SL;
	TransportP.SeenList -> SL;
}