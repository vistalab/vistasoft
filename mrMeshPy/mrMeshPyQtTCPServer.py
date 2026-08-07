 #!/usr/bin/python

'''
A TCP server in QT to handle mrVista throughput to mrMeshPy

Mark Hymers & Andre' Gouws 2017
'''


from PyQt5 import QtCore, QtGui, QtNetwork, QtWidgets

#local modules
from mp_Commands import run_mp_command

debug = True

class mrMeshPyQtTCPServer(QtNetwork.QTcpServer):
    def __init__(self, parent):
        super(mrMeshPyQtTCPServer, self).__init__(parent)
        
        # start up the server checking for incoming data
        self.newConnection.connect(self.startReceiveCommand)

        # place the parent object (mrMeshPyMainWindow) in the scope of the server
        self.mainWindow = parent

        # set up a counter for testing later #TODO remove? 
        self.counter = 0



    def startReceiveCommand(self):

        self.mainWindow.ui.lockedForProcessing = 1 #TODO remove? 

        self.socket = self.nextPendingConnection()
        print("Server waiting for incoming data ...")
        # Wait until we've read the command
        # TODO Add timeout?
        self.socket.waitForReadyRead(1000)

        # Parse command #TODO we assume a command will never be longer than 1024 bytes
        command = self.socket.read(1024).strip()

        # commands have multiple description strings that are ;separeated - unpack here
        incomingData = command.strip().split(';')
        
        # for testing
        if debug: 
            print('incomingData')
            print(incomingData)

        # lets start unpacking the incoming data packet
        # we expect anything coming in to first have a command (cmd)
        #  which is then followed by some specifically sized data blobs

        if incomingData[0] != 'cmd':
            #something has gone wrong - stop here
            print('error! - command string received but not recognised:')

        else:
            # we got a command
            print('Full incoming command is:')
            print(incomingData)
            
            # fields 2,3,and 4 (index 1,2,3) in the command string are placeholders -- ignore for now #TODO

            # the 5th field (zero index = 4) is the actual, sensibly-named command string e.g. paint_my_car           
            commandName = incomingData[4]

            # field 6 (index 5) -- the incoming command should always reference a particular mesh instance
            # Major change here - no longer an index - will be a unique string identifier related to clock
            theMeshInstance = incomingData[5]
            

            # field 7 onwards (may be multiple) are extra arguments specific to a particluar command
            
            # now check if there are any extra arguments (e.g. smoothing. threshold etc) and add to a list
            commandArgs = [] #placeholder
            for i in range(6,len(incomingData)):
                commandArgs.append(incomingData[i])
                
            # report the incoming command
            print('.. attempting to run command: %s\n with args: %s \n on mesh window %s ..' %(commandName, str(commandArgs), str(theMeshInstance)))

            #and try to run it
            run_mp_command(commandName, commandArgs, theMeshInstance, self.mainWindow.ui, self)

#            try:            
#                run_mp_command(commandName, commandArgs, theMeshInstance, self.mainWindow.ui, self)
#            
#            except Exception as e:
#                print("Bad command")
#                self.socket.write(str('cmd error'))



        ## TODO: generate some feedback output

#-----------------


class Dialog(QtWidgets.QDialog):
    def __init__(self, parent=None):
        super(Dialog, self).__init__(parent)

        self.server = mrMeshPyQtTCPServer()
        if not self.server.listen(QtNetwork.QHostAddress("127.0.0.1"), 9995):
        # if not self.server.listen(): #next available ## TODO may be better
            print("Error")
            return

        print("Running on %d" % self.server.serverPort())



if __name__ == '__main__':
    import sys
    app = QtWidgets.QApplication(sys.argv)
    dialog = Dialog()
    dialog.show()
    sys.exit(dialog.exec_())

