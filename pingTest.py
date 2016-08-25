from TestSim import TestSim

def main():
    s = TestSim();
    s.runTime(10);
    s.loadTopo("long_line.topo");
    s.loadNoise("no_noise.txt");
    s.bootAll();
    s.addChannel("command");
    s.addChannel("general");

    s.runTime(20);
    s.ping(1, 2, "Hello, World");
    s.runTime(10);
    s.ping(1, 10, "Hi!");
    s.runTime(20);

if __name__ == '__main__':
    main()
