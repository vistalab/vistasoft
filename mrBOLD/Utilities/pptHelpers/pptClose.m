function pptClose(op,ppt,pptFile);
% For Windows machines only: Close an ActiveX Server for 
% a particular power point file, saving along the way.
%
% Usage:
%   pptClose(op,ppt,pptFile);
%
% ras, 10/2005.
[p f ext] = fileparts(pptFile);
if ~isempty(p),
	callingDir = pwd; 
	cd(p); 
end
    
if ~exist(pptFile,'file')
  % Save file as new:
  invoke(op,'SaveAs',pptFile,1);
else
  % Save existing file:
  invoke(op,'Save');
end

% Close the presentation window:
invoke(op,'Close');

% % Quit PowerPoint
% invoke(ppt,'Quit');

% % Close PowerPoint and terminate ActiveX:
% delete(ppt);

if exist('callingDir', 'var')
	cd(callingDir);
end

return