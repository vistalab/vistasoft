function vw = setCurSlice(vw, sliceNum)
%
% vw = setCurSlice(vw, sliceNum)
%
% For VOLUME, updates the editable text.  For INPLANE/FLAT,
% selects button corresponding to sliceNum.
%
% djh, 8/98
% bw,  12.15.00
%     Made adjustment for setting FLAT view.  This was
%     needed to manage the new INPLANE UI with multiple slices.
% ras, 04/04
%     Made adjustments in parallel with changes in makeSlider
%     and setSlider, for inplane view
% ras, 06/06: now deals w/ hidden views, by using the tSeriesSlice
% field.
% ras, 02/07: fixed bug where using the tSeriesSlice field actually
% made getCurSlice not work.
%
% jw, 6/2010: Obsolete. Use vw = viewSet(vw, 'curslice', sliceNum) instead

warning('vistasoft:obsoleteFunction', 'setCurSlice.m is obsolete.\nUsing\n\tvw = viewSet(vw, ''curslice'', sliceNum)\ninstead.');

vw = viewSet(vw, 'curslice', sliceNum);

return

% vw.tSeriesSlice = sliceNum;
% 
% if isequal(vw.name,'hidden')
% 	return
% end
% 
% switch vw.viewType
% 	case 'Inplane'
% 		setSlider(vw,vw.ui.slice,sliceNum);
% 
% 		% remove the trailing digits
% 		str = sprintf('%.0f',sliceNum);
% 		set(vw.ui.slice.labelHandle,'String',str);
% 
% 	case {'Volume', 'Gray'}
% 		volSize = viewGet(vw,'Size');
% 		sliceOri=getCurSliceOri(vw);
% 		sliceNum=clip(sliceNum,1,volSize(sliceOri));
% 		set(vw.ui.sliceNumFields(sliceOri), 'String',num2str(sliceNum));
% 
% 	case 'Flat'
% 		if checkfields(vw, 'numLevels')
% 			% 'flat-level' vw
% 			if sliceNum > 2+vw.numLevels(1)
% 				h = 2;
% 			else
% 				h = 1;
% 			end
% 		else
% 			% regular flat vw
% 			if sliceNum <= 2
% 				h = sliceNum;
% 			else
% 				h = [1 2];  % both hemispheres at once
% 			end
% 		end
% 
% 		selectButton(vw.ui.sliceButtons,h)
% end
% return
