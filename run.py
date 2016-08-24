#ANDES Lab - University of California, Merced
#Author: UCM ANDES Lab
#$Author: abeltran2 $
#$LastChangedDate: 2014-08-31 16:06:26 -0700 (Sun, 31 Aug 2014) $
#! /usr/bin/python
import sys


from TOSSIM import *
from CommandMsg import *

t = Tossim([])
r = t.radio()
numMote=0

# Load a topo file and use it.
def loadTopo(topoFile):
   print 'Creating Topo!'
   # Read topology file.
   topoFile = 'topo/'+topoFile
   f = open(topoFile, "r")
   global numMote
   numMote = int(f.readline());

   print 'Number of Motes', numMote

   for line in f:
      s = line.split()
      if s:
         print " ", s[0], " ", s[1], " ", s[2];
         r.add(int(s[0]), int(s[1]), float(s[2]))

# Load a noise file and apply it.
def loadNoise(noiseFile):
   if numMote == 0:
      print "Create a topo first"
      exit();
   # Get and Create a Noise Model
   noiseFile = 'noise/'+noiseFile;
   noise = open(noiseFile, "r")
   for line in noise:
      str1 = line.strip()
      if str1:
         val = int(str1)
      for i in range(1, numMote+1):
         t.getNode(i).addNoiseTraceReading(val)

   for i in range(1, numMote+1):
      print "Creating noise model for ",i;
      t.getNode(i).createNoiseModel()

def bootNode(nodeID):
   if numMote == 0:
      print "Create a topo first"
      exit();

   t.getNode(nodeID).bootAtTime(1333*nodeID);

def bootAll():
   i=0;
   for i in range(1, numMote+1):
      bootNode(i);

def moteOff(nodeID):
   t.getNode(nodeID).turnOff();

def moteOn(nodeID):
   t.getNode(nodeID).turnOn();

def package(string):
 	ints = []
	for c in string:
		ints.append(ord(c))
	return ints

def run(ticks):
	for i in range(ticks):
		t.runNextEvent()

# Rough run time. tickPerSecond does not work.
def runTime(amount):
   i=0
   while i<amount*1000:
      t.runNextEvent() 
      i=i+1

#Create a Command Packet
msg = CommandMsg()

pkt = t.newPacket()
pkt.setData(msg.data)
pkt.setType(msg.get_amType())

# COMMAND TYPES
CMD_PING = 0
CMD_NEIGHBOR_DUMP = 1
CMD_ROUTE_DUMP=3

# Generic Command
def sendCMD(ID, dest, payloadStr):
   msg.set_dest(dest);
   msg.set_id(ID);
   msg.setString_payload(payloadStr)
   
   pkt.setData(msg.data)
   pkt.setDestination(dest)
   pkt.deliver(dest, t.time()+5)

def cmdPing(source, dest, msg):
   sendCMD(CMD_PING, source, "{0}{1}".format(chr(dest),msg));

def cmdNeighborDMP(destination):
   sendCMD(CMD_NEIGHBOR_DUMP, "neighbor command");

def cmdRouteDMP(destination):
   sendCMD(CMD_ROUTE_DUMP, "routing command");

def addChannel(channelName):
   print 'Adding Channel', channelName;
   t.addChannel(channelName, sys.stdout);


runTime(10);
loadTopo("long_line.topo");
loadNoise("no_noise.txt");
bootAll();
addChannel("cmdDebug");
addChannel("genDebug");

runTime(20);
cmdPing(1, 2, "Hello, World");
runTime(10);
cmdPing(1, 3, "Hi!");
runTime(3000);
