configuration FloodingC{
	provides interface Flooding;
}

implementation {
	components FloodingP;
	Flooding = FloodingP;

	components new SimpleSendC(AM_PACK);
	FloodingP.Sender -> SimpleSendC;

	components new ListC(pack, 64);
	FloodingP.SeenList -> ListC;

}
