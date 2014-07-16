% Script to clear the workspace when done with a mrVista session.
% It is best to run this prior to starting another mrVista session.
% Perhaps we should make it part of the QUIT options ... something like
% QUIT mrVista Session ....
%
% Wandell
%

clear global FLAT 
clear global GRAPHWIN 
clear global HOMEDIR 
clear global INPLANE 
clear global VOLUME 
clear global dataTYPES 
clear global mrLoadRetVERSION
clear global mrSESSION
clear global selectedFLAT 
clear global selectedINPLANE 
clear global selectedVOLUME 
clear global vANATOMYPATH
clear global MRFILES

%Clear all dictionary containers
clear global DictViewTranslate
clear global DictViewHelp
clear global DictViewHeadings