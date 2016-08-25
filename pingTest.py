from TestSim import TestSim

def main():
    s = TestSim();
    s.runTime(1);
    s.loadTopo("long_line.topo");
    s.loadNoise("no_noise.txt");
    s.bootAll();
    s.addChannel(s.COMMAND_CHANNEL);
    s.addChannel(s.GENERAL_CHANNEL);

    s.runTime(1);
    s.ping(1, 2, "Hello, World");
    s.runTime(1);
    s.ping(1, 10, "Hi!");
    s.runTime(1);

if __name__ == '__main__':
    main()
