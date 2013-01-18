% Script to remove averages
curAvStruct=dataTYPES(2);
scansToKEEP=[1:4];
curAvStruct.scanParams=curAvStruct.scanParams(scansToKEEP);
curAvStruct.blockedAnalysisParams=curAvStruct.blockedAnalysisParams(scansToKEEP);
curAvStruct.eventAnalysisParams=curAvStruct.eventAnalysisParams(scansToKEEP);
dataTYPES(2)=curAvStruct;
saveSession
