#!/usr/bin/python

'''
Send module for mrMeshPy viewer

The mrMeshPyServer uses the routines here to send data back to mrVista over the TCP socket.

Andre' Gouws 2017
'''

from numpy import *
import time

debug = True



def sendROIInfo(theMeshInstance, commandArgs, mainWindowUI, the_TCPserver):
    # when a request for ROI info comes in, this sends an initial confirmation that an ROI is available

    try:
        targetVTKWindow = mainWindowUI.vtkInstances[mainWindowUI.vtkDict[theMeshInstance]]
        data_to_send = targetVTKWindow._Iren.filledROIPoints

        num2send = len(data_to_send)
        if debug: print(num2send)

        the_TCPserver.socket.write(str('RoiReady,double,%i,' %num2send))
        return 0
    except:
        the_TCPserver.socket.write(str('NoROIData'))   
        return 1



def sendROIVertices(theMeshInstance, commandArgs, mainWindowUI, the_TCPserver):
    # when a request for ROI info comes we send the data after the confirmation (sendROIInfo above)
    targetVTKWindow = mainWindowUI.vtkInstances[mainWindowUI.vtkDict[theMeshInstance]] 
    data_to_send = targetVTKWindow._Iren.filledROIPoints

    the_TCPserver.socket.waitForReadyRead(10)

    formatData = array(data_to_send,'d')
    formatString = formatData.tostring()
    if debug: print(formatData)    
    if debug: print(formatString)
    if debug: print(len(formatString))
    the_TCPserver.socket.write(formatString)


