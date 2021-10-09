configuration NeighborDiscoveryC{
	provides interface NeighborDiscovery;
}

implementation {
	// components FloodingP;
	// Flooding = FloodingP;


    components NeighborDiscoveryP;
    NeighborDiscovery = NeighborDiscoveryP;

    components new TimerMilliC() as discoveryTimer;
    NeighborDiscoveryP.discoveryTimer -> discoveryTimer;

    components new ListC(Neighbor*, 64) as neighborList;
	NeighborDiscoveryP.Neighbors -> neighborList;

    components new SimpleSendC(AM_PACK);
	NeighborDiscoveryP.Sender -> SimpleSendC;

    components new ListC(pack, 64) as packList;
	NeighborDiscoveryP.SeenList -> packList;

    components new ListC(uint32_t, 64) as newList;
	NeighborDiscoveryP.NL -> newList;

    components FloodingC;
    NeighborDiscoveryP.Flooding -> FloodingC;

}