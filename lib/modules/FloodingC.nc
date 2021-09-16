configuration FloodingC{
	provides interface Flooding;
}

implementation {
	components FloodingP;
	Flooding = FloodingP;

	components new SimpleSendC(AM_PACK);
	FloodingP.Sender -> SimpleSendC;

	components new HashmapC(uint16_t, 20);
	FloodingP.SeenList -> HashmapC;

}
