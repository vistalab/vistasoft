function [PREFS ok] = publishFigureParams(view, PREFS);
% Get parameters/preferences for 'publishing' a Flat map.
%
%  PREFS = publishFigureParams(view, [PREFS]);
%
% 'Publishing' refers to the creation of an upsampled, high-quality
% rendering of a flat patch for publication/presentation purposes.
% The manner in which this is produced depends on several preferences,
% which can be set using this function.
%
% SEE ALSO: publishFigure.
%
% ras, 06/2008.
if notDefined('PREFS'), PREFS = struct;  end

if(isfield(PREFS,'plots') & isfield(PREFS.plots,'publishFigure'))
	% previously-specified values
	binaryAnatFlag = PREFS.plots.publishFigure.binaryAnatFlag;
	anatBlurIter = PREFS.plots.publishFigure.anatBlurIter;
	anatBlurIterPre = PREFS.plots.publishFigure.anatBlurIterPre;
	backRGB = PREFS.plots.publishFigure.backRGB;
	roiLineWidth = PREFS.plots.publishFigure.roiLineWidth;
	overlayBlurIter = PREFS.plots.publishFigure.overlayBlurIter;
	upSampIter = PREFS.plots.publishFigure.upSampIter;
	clipMode = PREFS.plots.publishFigure.clipMode;
	cbarFlag = PREFS.plots.publishFigure.cbarFlag;
	labelRois = PREFS.plots.publishFigure.labelRois;
	
else
	% default values
	binaryAnatFlag = 1;
	anatBlurIter = 1;
	anatBlurIterPre = 1;
	backRGB = [1 1 1];
	roiLineWidth = 2;
	overlayBlurIter = 0;
	upSampIter = 2;
	clipMode = [];
	cbarFlag = ~isequal( viewGet(view, 'displayMode'), 'anat' );
	labelRois = 1;

end

dlg(1).fieldName = 'binaryAnatFlag';
dlg(1).style = 'checkbox';
dlg(1).string = 'Make anatomy binary';
dlg(1).value = binaryAnatFlag;

dlg(end+1).fieldName = 'anatBlurIterPre';
dlg(end).style = 'number';
dlg(end).string = 'Initial Anatomy blur (0-5)';
dlg(end).value = anatBlurIterPre;

dlg(end+1).fieldName = 'anatBlurIter';
dlg(end).style = 'number';
dlg(end).string = 'Post-threshold Anatomy blur (0-5)';
dlg(end).value = anatBlurIter;

dlg(end+1).fieldName = 'overlayBlurIter';
dlg(end).style = 'number';
dlg(end).string = 'Data overlay blur (0-5)';
dlg(end).value = overlayBlurIter;

dlg(end+1).fieldName = 'upSampIter';
dlg(end).style = 'number';
dlg(end).string = 'Upsample factor (0-5)';
dlg(end).value = upSampIter;

dlg(end+1).fieldName = 'backRGB';
dlg(end).style = 'number';
dlg(end).string = 'background RGB (eg. [0 0 0])';
dlg(end).value = backRGB;

dlg(end+1).fieldName = 'roiLineWidth';
dlg(end).style = 'number';
dlg(end).string = 'ROI line width';
dlg(end).value = roiLineWidth;

dlg(end+1).fieldName = 'clipMode';
dlg(end).style = 'number';
dlg(end).string = 'Clip Mode (eg. auto, [0 pi], blank for default)';
dlg(end).value = clipMode;

dlg(end+1).fieldName = 'cbarFlag';
dlg(end).style = 'checkbox';
dlg(end).string = 'Show color bar';
dlg(end).value = cbarFlag;

dlg(end+1).fieldName = 'labelRois';
dlg(end).style = 'checkbox';
dlg(end).string = 'Show ROI legend';
dlg(end).value = labelRois;

[resp ok] = generalDialog(dlg, 'Publish Flat Figure');
if ok
	PREFS.plots.publishFigure.binaryAnatFlag = resp.binaryAnatFlag;
	PREFS.plots.publishFigure.anatBlurIter = resp.anatBlurIter;
	PREFS.plots.publishFigure.anatBlurIterPre = resp.anatBlurIterPre;
	PREFS.plots.publishFigure.backRGB = resp.backRGB;
	PREFS.plots.publishFigure.roiLineWidth = resp.roiLineWidth;
	PREFS.plots.publishFigure.overlayBlurIter = resp.overlayBlurIter;
	PREFS.plots.publishFigure.upSampIter = resp.upSampIter;
	PREFS.plots.publishFigure.clipMode = resp.clipMode;
	PREFS.plots.publishFigure.cbarFlag = resp.cbarFlag;
	PREFS.plots.publishFigure.labelRois = resp.labelRois;
end


return;




% older code:

% prompt = {'Make anatomy binary:',...
% 	'Initial Anatomy blur (0-5):',...
% 	'Post-threshold Anatomy blur (0-5):',...
% 	'Data overlay blur (0-5):',...
% 	'Upsample factor (0-5):',...
% 	'background RGB (eg. [0 0 0]):',...
% 	'ROI line width:',...
% 	'Clip Mode (eg. auto, [0 pi], blank for default):',...
% 	'Show color bar',...
% 	'Show ROI legend'};
% defAns = {num2str(binaryAnatFlag),...
% 	num2str(anatBlurIterPre),...
% 	num2str(anatBlurIter),...
% 	num2str(overlayBlurIter),...
% 	num2str(upSampIter),...
% 	num2str(backRGB),...
% 	num2str(roiLineWidth),...
% 	num2str(clipMode),...
% 	num2str(cbarFlag),...
% 	num2str(labelRois)};
% resp = inputdlg(prompt, 'Set Publish Parameters', 1, defAns);
% 
% if(~isempty(resp))
% 	binaryAnatFlag = str2num(resp{1});
% 	anatBlurIterPre = str2num(resp{2});
% 	anatBlurIter = str2num(resp{3});
% 	overlayBlurIter = str2num(resp{4});
% 	upSampIter = str2num(resp{5});
% 	backRGB = str2num(resp{6});
% 	roiLineWidth = str2num(resp{7});
% 	if(isempty(str2num(resp{8})))
% 		clipMode = resp{8};
% 	else
% 		clipMode = str2num(resp{8});
% 	end
% 	cbarFlag = str2num(resp{9});
% 	labelRois = str2num(resp{10});
% 	PREFS.plots.publishFigure.binaryAnatFlag = binaryAnatFlag;
% 	PREFS.plots.publishFigure.anatBlurIter = anatBlurIter;
% 	PREFS.plots.publishFigure.anatBlurIterPre = anatBlurIterPre;
% 	PREFS.plots.publishFigure.backRGB = backRGB;
% 	PREFS.plots.publishFigure.roiLineWidth = roiLineWidth;
% 	PREFS.plots.publishFigure.overlayBlurIter = overlayBlurIter;
% 	PREFS.plots.publishFigure.upSampIter = upSampIter;
% 	PREFS.plots.publishFigure.clipMode = clipMode;
% 	PREFS.plots.publishFigure.cbarFlag = cbarFlag;
% 	PREFS.plots.publishFigure.labelRois = labelRois;
% end