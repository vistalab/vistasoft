function rmPlotGUIupdateTogether(flag, plots)
% Routine to turn on/off updateAllWindows flag for rmPlotGUI windows: If
% the flag is set to true, then whenever the voxel number changes in one
% rmPlotGUI window, the voxel number changes in other windows as well. This
% is useful for viewing multiple models of the same data set
% simultaneously.
%
% Example. Turn on updateAllWindows flag:
%   rmplotGUIupateTogether(true)
% Example. Turn off updateAllWindows flag:
%   rmplotGUIupateTogether(false)

if notDefined('flag'),  flag = true;   end
if notDefined('plots'), plots = 1:100; end
theplots = [];

for ii = plots;
    try  %#ok<TRYNC>
        x = get(ii, 'UserData'); 
        if checkfields(x, 'ui', 'voxel', 'sliderHandle')
            theplots = [theplots ii];
        end
    end
end
for ii = theplots
    A = get(ii, 'UserData');
    A.updateAllWindows = flag;
    rmPlotGUI_update(A);
end


