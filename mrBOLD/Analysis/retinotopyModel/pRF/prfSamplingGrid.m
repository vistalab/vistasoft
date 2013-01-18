function [x y step] = prfSamplingGrid(params);
% Return the sampling grid for stimuli and pRFs, given retinotopy model
% parameters.
%
%  [x y step] = prfSamplingGrid(params);
%
% ras, 08/15/08.
mx = params.analysis.fieldSize; 	
step = params.analysis.sampleRate; 	 
mygrid = -mx:step:mx; 	 
[x y] = meshgrid(mygrid);
% The following does not always recreate the original grid. Better to 
% recreate grid with original algorithm. See rfPlot for logic.
% (ras, 08/08 local version: the above doesn't seem to work for me: not
% sure rmMain actually does that anymore.)
% x = meshgrid( unique(params.analysis.X), unique(params.analysis.Y) );

return
