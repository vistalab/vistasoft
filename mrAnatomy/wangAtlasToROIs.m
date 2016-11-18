function vw = wangAtlasToROIs(vw, wangAtlasNifti)
%
% Converts Wang Atlas from freesurfer MGZ volume to vistasoft ROIs
%
% Example
%   fsID = 'ernie';
%

hideGrayROIs = viewGet(vw, 'hide gray ROIs');
vw = viewSet(vw, 'hide Gray ROIs', true);


Wang_ROI_Names = {...
    'V1v' 'V1d' 'V2v' 'V2d' 'V3v' 'V3d' 'hV4' 'VO1' 'VO2' 'PHC1' 'PHC2' ...
    'TO2' 'TO1' 'LO2' 'LO1' 'V3B' 'V3A' 'IPS0' 'IPS1' 'IPS2' 'IPS3' 'IPS4' ...
    'IPS5' 'SPL1' 'FEF'};

wangComments = 'ROI made based on maximum probabilty map from Wang et al, 2014 ''Probabilistic Maps of Visual Topography in Human Cortex''';


% count the current number of ROIs
nROIs = length(viewGet(vw, 'ROIs'));

% create new ROIs from atlas
vw = nifti2ROI(vw, wangAtlasNifti);

% how many new ROIs did we get?
numNewROIs = length(viewGet(vw, 'ROIs')) - nROIs;
assert(numNewROIs>0)

for jj = 1:numNewROIs
    this_roi       = viewGet(vw, 'ROI name', nROIs + jj);
    this_roi_num   = str2double(this_roi(regexp(this_roi, '[0-9]')));
    this_roi_name  = sprintf('WangAtlas_%s', Wang_ROI_Names{this_roi_num});
    vw             = viewSet(vw, 'ROI Name', this_roi_name, nROIs + jj);
    comments       = viewGet(vw, 'ROI comments', nROIs + jj);
    comments       = sprintf('%s\n%s', comments, wangComments);
    vw             = viewSet(vw, 'ROI comments', comments, nROIs + jj);
end



vw = viewSet(vw, 'hide Gray ROIs', hideGrayROIs);

return
%
%
% colors = jet(25);
%
% colors = colors(randperm(25),:)
%
% for ii = 1:length(vw.ROIs); vw.ROIs(ii).color = colors(ii,:); end


