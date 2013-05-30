function slice = cropCurAnatSlice(vw,curSlice)
%
% function slice = cropCurAnatSlice(vw,[slice])
%
% Pulls slice from vw.anat. Defaults to 
% current slice.
%
% djh, 7/98
% ras, 01/05 added slice as input arg
if ieNotDefined('curSlice')
	% Get curSlice from ui
	curSlice = viewGet(vw, 'Current Slice');
end
dims = viewGet(vw,'Size');

switch viewGet(vw,'View Type')

  case 'Inplane'
      slice = viewGet(vw,'Anatomy Current Slice',curSlice);
      if isempty(slice)
          disp('Warning: Anatomies not loaded');
          slice = zeros(dims(1:2));
      end
    
  case {'Volume','Gray','generalGray'}
    curSliceOri = getCurSliceOri(vw);
    if ~isempty(vw.anat)
      switch curSliceOri
        case 1
          slice = squeeze(vw.anat(curSlice,:,:));
	case 2
	  slice = squeeze(vw.anat(:,curSlice,:));
	case 3
          slice = vw.anat(:,:,curSlice);
      end
    else
      disp('Warning: Anatomies not loaded');
      switch curSliceOri
        case 1
	  slice = zeros(dims(2:3));
	case 2
	  slice = zeros([dims(1) dims(3)]);
	case 3
	  slice = zeros(dims(1:2));
      end
    end

  case {'Flat','FlatLevel'}
    if ~isempty(vw.anat)
      slice = vw.anat(:,:,curSlice);
    else
      disp('Warning: Anatomies not loaded');
      slice = zeros(dims(1:2));
    end
    
end

return
