function fgData = dtiPlotValFromFibersBetweenROIs(dt6,fg,xform,ROI1,ROI2,valName,interpMethod,numSteps,labelStr)
% Plots tensor properties along the fiber group
% 
%    fgData = dtiPlotValFromFibersBetweenROIs(dt6,fg,xform,ROI1,ROI2[valName],[interpMethod],[numSteps],[labelStr])
%
% Inputs:
%    dt6          - dt6 data (XxYxZx6)
%    fg           - fiber group structure
%    xform        - the transform that converts fg's coords to dt6 indices
%    valName      - 'eigVal', 'shape', 'fa', 'md', or 'val' (default = 'fa');
%    interpMethod - 'nearest', 'trilin', or 'spline' (default = 'trilin');
%    numSteps     - number of steps along the fiber pathways to be plotted
%    labelStr     - Display string for plotting values (this will be
%                   overwritten for valName = 'shape' or 'eigVal'.
%
% Output:
%    fgData - If valName is 'eigVal' or 'shape', fgData is a 3x1 cell
%             object.  The cell contains data for 1st, 2nd and 3rd
%             eigenvalues or linearity, planarity and sphericity.
%             Otherwise, fgData contains the data for fractional anisotropy
%             or mean diffusivity.
% 
% History:
%    2008.04.10 AJS: Wrote it.
%

% Clip fibers between ROIs
fgClip = dtiClipFiberGroupToROIs(fg,ROI1,ROI2);

% Plot fiber values
if ieNotDefined('valName'),      valName = 'fa';                              end
if ieNotDefined('interpMethod'), interpMethod = 'trilin';                     end
if ieNotDefined('numSteps'),     numSteps = max(cellfun('size',fg.fibers,2)); end
if ieNotDefined('labelStr'),     labelStr=[]; end

fgData = dtiPlotValFromFibers(dt6,fgClip,xform,valName,interpMethod,numSteps,labelStr);

return

%% Examples

% Example of Scalar data: See dtiPlotValFromFibers.m for more
% load dt6 data
subjDir = 'C:\cygwin\home\sherbond\data\aab050307'; %#ok<UNRCH>
fg = dtiReadFibers(fullfile( subjDir,'fibers','conTrack','or_clean','LOR_meyer_final.mat'));
ROI1 = dtiReadRoi(fullfile(subjDir,'ROIs','llgn_tony.mat'));
ROI2 = dtiReadRoi(fullfile(subjDir,'ROIs','lv1.mat'));
dt = load(fullfile(subjDir,'dti06','dt6.mat'));
pddD = niftiRead(fullfile(subjDir,dt.files.pddDisp));
xformToAcpc = pddD.qto_xyz;
pddD = pddD.data;
fgData = dtiPlotValFromFibersBetweenROIs(pddD,fg,inv(xformToAcpc),ROI1,ROI2,'val',[],[],'Dispersion (degrees)');

