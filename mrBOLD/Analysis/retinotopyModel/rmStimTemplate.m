function sParams = rmStimTemplate(vw, nScans)
% Defines the retinotopy model stimulus slot
%
%    sParams = rmStimTemplate(vw, nScans)
%
% This routine defines all of the parameters in a rm stimulus.  If you ever
% change the default, you must edit this function

n = viewGet(vw,'nscans');
if notDefined('nScans'), nScans = n; end

sParams = struct;

for ii=1:nScans

    sParams(ii).stimType   = '8Bars';
    sParams(ii).stimSize   =  14;
    sParams(ii).stimWidth  =  45;
    sParams(ii).stimStart  =  0;
    sParams(ii).stimDir    =  0;
    sParams(ii).nCycles    =  6;
    sParams(ii).nStimOnOff =  0;
    sParams(ii).nUniqueRep =  1;
    sParams(ii).prescanDuration = 8;
    sParams(ii).nDCT = 0;
    sParams(ii).hrfType =  'one gamma (Boynton style)';  % 'two gammas (SPM style)'
    sParams(ii).hrfParams = {[1.68 3 2.05],[5.4 5.2 10.8 7.35 0.35]};

    %If we are within the number scans in the dataTYPES, get frame
    %parameters from the view struct
    if ii <= n, 
        sParams(ii).framePeriod = viewGet(vw,'framePeriod',ii);
        sParams(ii).nFrames     = viewGet(vw,'nFrames',ii);
    % Otherwise copy them from the previous scan
    else
        sParams(ii).framePeriod = sParams(ii-1).framePeriod;
        sParams(ii).nFrames     = sParams(ii-1).nFrames;
    end

    sParams(ii).fliprotate = [0 0 0];
    sParams(ii).imFile      = 'None';
    sParams(ii).jitterFile  = 'None';
    sParams(ii).paramsFile  = 'None';
    sParams(ii).imFilter    = 'None';

end
