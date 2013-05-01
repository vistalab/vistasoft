function save4DTSeries(vw,tMat,scan)
%
% save4DTSeries(view,tMat,scan);
% 
% Save a 4D tSeries (tMat) in the proper format
% for the specified view and scan.
%
% Currently works for inplane tSeries only.
%
% ras 03/05.
if ~isequal(viewGet(vw,'View Type'),'Inplane')
    error('Sorry, only Inplanes for now.')
end

tMat = int16(tMat);

savetSeries(tMat,vw,scan);

return