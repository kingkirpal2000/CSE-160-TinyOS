configuration LinkStateC{
	provides interface LinkState;
}

implementation {
	components LinkStateP;
	LinkState = LinkStateP;

    components new TimerMilliC() as LStimer;
    LinkStateP.LStimer -> LStimer;

	components new TimerMilliC() as Dtimer;
    LinkStateP.DTimer -> Dtimer;

	components new SimpleSendC(AM_PACK);
	LinkStateP.Sender -> SimpleSendC;

	// components new ListC(pack, 100);
	// FloodingP.SeenList -> ListC;

	components NeighborDiscoveryC;
    LinkStateP.NeighborDiscovery -> NeighborDiscoveryC;

	components TransportC;
	LinkStateP.Transport -> TransportC;

	components RandomC as Random;
	LinkStateP.Random -> Random;

	components new ListC(pack, 100) as SL;
	LinkStateP.SeenList -> SL;



}
