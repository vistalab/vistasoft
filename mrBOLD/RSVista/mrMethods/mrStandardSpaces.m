function spaces = mrStandardSpaces(mr);
%
% spaces = mrStandardSpaces(mr);
%
% Build some standard space definitions for mrViewer,
% including the default pixel space and an L/R flipped
% space.
%
% ras 07/05.
spaces(1).name = 'Raw Data in Pixels';
spaces(1).xform = eye(4);
spaces(1).dirLabels = {'Rows' 'Columns' 'Slices'};
spaces(1).sliceLabels =  {'Rows' 'Columns' 'Slices'};
spaces(1).units = 'pixels';
spaces(1).coords = [];
spaces(1).indices = [];

spaces(end+1).name = 'Raw Data in mm';
spaces(end).xform = affineBuild([0 0 0],[0 0 0],mr.voxelSize);
spaces(end).dirLabels = {'Rows' 'Columns' 'Slices'};
spaces(end).sliceLabels =  {'Rows' 'Columns' 'Slices'};
spaces(end).units = 'mm';
spaces(end).coords = [];
spaces(end).indices = [];

spaces(end+1).name = 'L/R Flipped';
spaces(end).xform = affineBuild([0 mr.dims(2)+1  0],[0 0 0],[1 -1 1]);
spaces(end).dirLabels = {'Rows' 'Columns' 'Slices'};
spaces(end).sliceLabels =  {'Rows' 'Columns' 'Slices'};
spaces(end).units = 'pixels';
spaces(end).coords = [];
spaces(end).indices = [];



% if I|P|R space is defined, create a radiological space
% by L/R flipping this space
if ~isempty(mr.spaces)
    names = {mr.spaces.name};
    if ~isempty(cellfind(names,'I|P|R'))
        j = cellfind(names,'I|P|R');
        spaces(end+1).name = 'Radiological';
        spaces(end).xform = spaces(2).xform * mr.spaces(j).xform;
        spaces(end).dirLabels = {'S <--> I'  'A <--> P'  'R <--> L'};
        spaces(end).sliceLabels =  {'Axial' 'Coronal' 'Sagittal'};
        spaces(end).units = 'pixels';
        spaces(end).coords = [];
        spaces(end).indices = [];
    end
end


return
