configuration LinkStateC{
	provides interface LinkState;
}

implementation {
	components LinkStateP;
	LinkState = LinkStateP;

    components new TimerMilliC() as LStimer;
    LinkStateP.LStimer -> LStimer;

	components new SimpleSendC(AM_PACK);
	LinkStateP.Sender -> SimpleSendC;

	// components new ListC(pack, 100);
	// FloodingP.SeenList -> ListC;

	components NeighborDiscoveryC;
    LinkStateP.NeighborDiscovery -> NeighborDiscoveryC;

	components RandomC as Random;
	LinkStateP.Random -> Random;

	components new ListC(pack, 100);
	LinkStateP.SeenList -> ListC;

}
