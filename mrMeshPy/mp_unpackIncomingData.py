#!/usr/bin/python

'''
This module interprets the commands sent from mrVista output to 
mrMeshPy (python) through the mrMeshPyServer .. 

Matlab sends a string in one transaction giving a command to the 
visualisation module. This command either performs an explicit
function in the viewer (e.g. rotate the camera 90 degrees) or the
commnd describes the configuration/content of a large data chunk to
will be sent in the subsequent transaction so that we know how to
unpack the data, and how to process it (e.g. 70,000 floating point
numbers which are scalar values to show as an amplitude map. 

Each command string is interpreted by the pm_commandInterpret module.

N.B. - currently command strings have a maximum length of 1024 bytes.

Commands are specifically ordered, semi-colon seperated strings which are 
unpacked to describe what the user is trying to do / send from matlab.
Commands have a MINIMUM LENGTH of 6 arguments and have the following 
structure and item order (zero-indexed)

0 - "cmd"  -- always this, identifies it as a cmd :)
1 - "drawOnly" or "newData" - allows an immediate action or tells 
            the program the content of the next TCP transaction
2 - "None" if no data is incoming, "i" integer, "d" double", "f" float etc
3 - integer  -- the number of samples we are sending
4 - commandName - should match a command in mp_Commands file
5 - theMeshInstance - integer pointing to the the mesh window that we
            want to operate on
6 onwards - commandArgs - a list of comma-separated pairs of arguments 
            to characterise the processing of the incoming data
            blob or apply some settings to the viewport -
            CAN BE EMPTY but must be set to []


Andre' Gouws 2017
'''

import struct

#local modules
from mp_Commands import *


debug = False



def unpackData(incomingDataType, incomingNumberOfSamples, the_TCPserver):

    try:
        # lets determine the size and nature of the incoming data

        # .. and how many bytes will that be?
        incomingBytes = struct.calcsize(incomingDataType)*incomingNumberOfSamples

        # report
        print('Expecting %i bytes from %i samples of %s dataType ... waiting ...' %(incomingBytes, incomingNumberOfSamples, incomingDataType))

        ##### Read number of data bytes ## TODO revise the weird behaviour here
        ####the_TCPserver.socket.waitForReadyRead()

        # report started
        print("socket open")

        # a placeholder that we append the incoming string to
        dataReceived = '' 

        # lets keep track of how many bytes we have actually received
        bytesReceived = 0
        
        # .. start reading ## TODO - 10ms timeout here OK?
        while bytesReceived < incomingBytes:
            the_TCPserver.socket.waitForReadyRead(10)
            if debug: print('bytesReceived', bytesReceived)
            tmp = the_TCPserver.socket.read(incomingBytes-bytesReceived)
            bytesReceived += len(tmp)
            dataReceived += tmp

        print('read completed ... ')

        # now unpack the data to 
        dataObject = struct.unpack(incomingNumberOfSamples*incomingDataType, dataReceived)
        print('unpacked %i data points.. ' %incomingNumberOfSamples)
        print('done loading incoming data!')

        if debug: print(dataObject[-10])
    
        return dataObject

    except Exception as e:
        print("Trouble unpacking data")


