function vw = rmLoadParameters(vw)
% rmLoadParameters - define scan and stimulus parameters for analysis
%
%  vw = rmLoadParameters(vw);
%
% Called from the Analysis | Retinotopy Model | Load Stimulus and Analaysis Parameters
% 
% 2006/06 SOD: wrote it.

if notDefined('vw'),
  fprintf('[%s]:No view struct provided\n',mfilename);
  return;
end

% now actually define scan/stim and analysis parameters (should
% these be separate?)
params = rmDefineParameters(vw);

% make stimulus and add it to the parameters
params = rmMakeStimulus(params);

% store params in view struct
vw  = viewSet(vw,'rmParams',params);

return
