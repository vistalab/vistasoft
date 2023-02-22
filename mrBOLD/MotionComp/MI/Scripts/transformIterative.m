%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%    gb 05/08/05
%
% This script has to be executed directly in the command line
% It is an attempt to create an interative transformation on the 
% reference scans.
%
%   1st step: register scan6 with reference scan5
%   2nd step: register scan6 and scan5 with reference scan4
%   etc...
%
% The current inplane has to be stored into the variable vw
%
% example :
%
%   close all
%   clear all
%   mrVista
%   vw = getSelectedInplane;
%   transformIterative
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
close all

for i = 5:-1:1
    mrVista;
    vw = getSelectedInplane;

    ROI = zeros([sliceDims(vw,1) size(vw.anat,3)]);
    ROI(80:100,35:70,15:19) = ones(21,36,5);
    
    if i == 5
        motionCompMutualInfMeanInit(vw,(i + 1):6,ROI,i,['OccLobeIterative' num2str(i)],'Original',1,0);
    else
        motionCompMutualInfMeanInit(vw,(i + 1):6,ROI,i,['OccLobeIterative' num2str(i)],['OccLobeIterative' num2str(i + 1)],1,0);
    end
    
    clear all
    close all
end

for i = 5:-1:1
    mrVista;
    vw = getSelectedInplane;
    
    if i == 5
        motionCompMutualInfMeanInit(vw,(i + 1):6,'',i,['RigidDtiIterative' num2str(i)],'Original',1,1);
    else
        motionCompMutualInfMeanInit(vw,(i + 1):6,'',i,['RigidDtiIterative' num2str(i)],['RigidDtiIterative' num2str(i + 1)],1,1);
    end
    
    clear all
    close all
end