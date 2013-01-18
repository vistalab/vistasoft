function curSlice = getCurSlice(vw)
%
% curSlice = getCurSlice(vw)
%
% For VOLUME, gets the curSlice from the sliceOriButtons and the
% ui.slice field.  For INPLANE/FLAT, gets curSlice from the
% sliceButtons handles.
%
% djh, 8/98
% ras, 06/05: now deals w/ hidden views: if it's hidden,
% uses the tSeriesSlice field.
% jw, 6/2010: Obsolete. Use curSlice = viewGet(vw, 'Current Slice') instead

warning('vistasoft:obsoleteFunction', 'getCurSlice.m is obsolete.\nUsing\n\tcurSlice = viewGet(vw, ''Current Slice'')\ninstead.');

curSlice = viewGet(vw, 'curSlice');

return


% if isequal(vw.name,'hidden')
%     % no UI or slider -- use tSeries slice
%     curSlice = vw.tSeriesSlice;
%     if isnan(curSlice)
%         curSlice = 1;
%     end
%     return
% end
% 
% switch vw.viewType
% case 'Inplane'
%    curSlice = vw.tSeriesSlice; % err on the side of not needing a UI
%    if isnan(curSlice) & checkfields(vw, 'ui', 'slice')
%        curSlice = get(vw.ui.slice.sliderHandle,'val');
%    end
% case {'Volume','Gray','generalGray'}
%    sliceOri=getCurSliceOri(vw);
%    curSlice=str2num(get(vw.ui.sliceNumFields(sliceOri),'String'));
% case 'Flat'
%     if isfield(vw,'numLevels') % test for levels vw
% 		%% flat-levels vw (older, but still supported)
%         curSlice = getFlatLevelSlices(vw);
%         curSlice = curSlice(1);
% 	else
% 		%% regular flat vw: slice is hemisphere, slice 3 means both
%        curSlice = findSelectedButton(vw.ui.sliceButtons);
% 	end   
% end
% 
% return;
% 
