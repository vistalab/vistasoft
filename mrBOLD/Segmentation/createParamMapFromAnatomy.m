function view=createParamMapFromAnatomy(view)
% anatomyParamMap=createParamMapFromAnatomy(view)
%
% Creates a gray parameter map from the gray matter values in each gray node
% Only works in gray mode
% Author ARW 050805: Wrote it.
% Example : VOLUME{1}=createParamMapFromAnatomy(VOLUME{1})
%
% 
mrGlobals;

if ~strcmp(view.viewType,'Gray')
    error('This function requires a Gray view');
end

% 
% if (ieNotDefined('view.anat'))
%     error('Anat must be loaded');
% end

% Find out the size of the 'anat' field in the view.
anatSize=size(view.anat);

% Check here in case anat is not loaded...

% Now turn the coords into indices
grayMatterIndices=sub2ind(anatSize,view.coords(1,:),view.coords(2,:),view.coords(3,:));

map=view.anat(grayMatterIndices);
nScans=length(dataTYPES(view.curDataType).scanParams);
for t=1:nScans
    view.map{t}=[];
end

view.map{getCurScan(view)}=map;
