configuration FloodingC{
	provides interface Flooding;
}

implementation {
	components FloodingP;
	Flooding = FloodingP;

	components new SimpleSendC(AM_PACK);
	FloodingP.Sender -> SimpleSendC;

	components new ListC(pack, 100);
	FloodingP.SeenList -> ListC;

	components NeighborDiscoveryC;
    FloodingP.NeighborDiscovery -> NeighborDiscoveryC;

	components LinkStateC;
    FloodingP.LinkState -> LinkStateC;


}
