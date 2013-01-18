function [whichScans,ok] = er_selectScans(vw, title)
% [whichScans, ok] = er_selectScans(vw, title);
%
% Like selectScans, provides a prompt to select a subset
% of scans for the current view/data Type, returning an
% array of the scan numbers selected. 
% 
% I like this a litte better than select scans, b/c it
% gives the annotation for each scan, and makes multi select
% easier.
%
%
% 04/05/04 ras.
global dataTYPES;

if ~exist('title','var')    title = 'Choose scans:';    end

whichSeries = vw.curDataType;
nscans = viewGet(vw, 'numScans');
scanList    = cell(1, nscans);
for i = 1:nscans
    scanList{i} = dataTYPES(whichSeries).scanParams(i).annotation;
    if isempty(scanList{i}), scanList{i} = sprintf('Scan%i',i); end
end

[whichScans, ok] = listdlg('PromptString',title,...
    'ListSize',[300 400],...
    'ListString',scanList,'InitialValue',1 ,'OKString','OK');

% Maybe we should check the return and announce of there is a problem?

return