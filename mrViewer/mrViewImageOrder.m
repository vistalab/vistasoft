function [order, nrows, ncols] = mrViewImageOrder(ui,nrows,ncols);
%
% [order, nrows, ncols] = mrViewImageOrder(ui,[nrows,ncols]);
%
% Return a matrix specifying the order in which
% to display different images in a mrViewer UI.
%
% The order matrix takes into acount the view format
% settings, such as whether a multi-view is being
% used or wheter a montage view is being used. It is
% a 2-D matrix of size nrows by ncols, where nrows and
% ncols are the number of rows and columns of subplots
% to display. The nonzero elements of order are indices
% into the images cell array (see mrViewUnderlay). A zero
% indicates no image will be displayed there.
%
% Really, this is much simpler than it sounds. :)
%
% nrows and ncols are optional arguments if you are running
% w/o a GUI and want to manually specify the size of a montage
% image. Otherwise, a better idea is to go back and add montage
% rows and columns settings to be specified by mrViewSet.
%
% ras, 07/07/05.
if ~exist('ui','var') | isempty(ui), ui = get(gcf,'UserData'); end

format = ui.settings.displayFormat;
ori = ui.settings.ori;

switch format
    case 1, % montage view
        if ~exist('nrows','var') | isempty(nrows)
            nrows = get(ui.controls.montageRows.sliderHandle,'Value');
        end
        if ~exist('ncols','var') | isempty(ncols)
            ncols = get(ui.controls.montageCols.sliderHandle,'Value');
        end
        nrows = round(nrows);
        ncols = round(ncols);

        order = zeros(ncols,nrows); % will transpose below

        % figure out # of slices to display
        % (fill up all subplots if possible, otherwise
        % go to total # slices available)
        slice = ui.settings.slice;
        totalSlices = ui.mr.dims(ori);
        nSlices = min(nrows*ncols,totalSlices-slice+1);

        % plug in the values, transpose to row-major
        order(1:nSlices) = 1:nSlices;
        order = order';
    case 2, % multi view
        order = [3 2; 0 1];
        nrows = 2;
        ncols = 2;
    case 3, % single slice
        order = 1;
        nrows = 1;
        ncols = 1;
end

return
