configuration AppC {
    provides interface App;
}

implementation {
    components AppP;
    App = AppP;

    components new SimpleSendC(AM_PACK);
	AppP.Sender -> SimpleSendC;

    components LinkStateC;
    AppP.LinkState -> LinkStateC;

    components TransportC;
    AppP.Transport -> TransportC;

    components new ListC(pack, 100) as SL;
	AppP.SeenList -> SL;


}