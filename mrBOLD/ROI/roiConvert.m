function roi = roiConvert(oldRoi,inplane);
% Convert a mrVista 1.0 ROI to a 2.0 ROI.
%
% roi = roiConvert(oldRoi,[inplane]);
%
% oldRoi can be an ROI struct, or a path to a .mat
% file where the ROI is saved. 
%
% inplane is the inplane anatomy on which the ROI was
% defined, loaded as an MR object (via mrLoad). It is
% required for Inplane ROIs, but not Gray/Volume ROIs.
%
% Flat ROIs are not yet supported.
%
%
% ras, 10/2005
if ischar(oldRoi), load(oldRoi,'ROI'); oldRoi = ROI; end

roi = [];

switch oldRoi.viewType
    case 'Inplane'
        roi = roiCreate(inplane,oldRoi.coords,'name',oldRoi.name,...
                        'color',oldRoi.color);
        roi.comments = 'Converted from mrVista 1.0 Inplane ROI';
    case {'Volume', 'Gray'}
        roi = roiCreate('I|P|R',oldRoi.coords,'name',oldRoi.name,...
                        'color',oldRoi.color);
        roi.comments = sprintf('Converted from mrVista 1.0 %s ROI',...
                                oldRoi.viewType);
    case 'Flat'
        error('Sorry, Flat ROIs are not yet supported.')
end

return