function dataViewNumber = atlasGuessDataView(atlasView)
%
%  dataViewNumber = atlasGuessDataView(atlasView)
%
%Author: Brewer, Wandell
%Purpose:
%   When we are analyzing FLAT atlases and data, there can be several FLAT
%   windows open.  We need to know which is the FLAT data window of
%   interest.  Fpr example, FLAT{3} may contain the data and FLAT{1} may
%   contain the atlas.    This can be confusing, so we wrote this routine
%   to help the user find which FLAT view contains that data used in atlas
%   fitting.
%

global FLAT

thisName = atlasView.name;
l = find( thisName == '{' );
thisNumber = str2num(thisName(l+1));
possibleFlat = [];

nFlat = length(FLAT);
for ii = 1:nFlat
    if ~isempty(FLAT{ii}) & ii ~= thisNumber
        possibleFlat = [possibleFlat,ii];
    end
end

if length(possibleFlat) == 1, 
    dataViewNumber = possibleFlat; 
    return;
else
   prompt={'Choose the FLAT cell that contains the data:'};
   def={num2str(possibleFlat)};
   dlgTitle='Select data view';
   lineNo=1;
   answer=inputdlg(prompt,dlgTitle,lineNo,def);
   dataViewNumber = num2str(answer{1});
end

return;