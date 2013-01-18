function M = rxMovie(rx);
%
%  M = rxMovie(rx);
%
% Play a movie (using mplay, java required)
% of the loaded rx tSeries and slice.
%
% Returns a movie object M.
%
% ras 03/05
if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

% check that there's a tSeries loaded
if ~isfield(rx,'tSeries') | isempty(rx.tSeries)
    myWarnDlg('You need to load tSeries first. Select File | Load | mrVista tSeries.')
    return
end

% get current slice
rxSlice = get(rx.ui.rxSlice.sliderHandle,'Value');

% put up the movie
rxTSeries = squeeze(rx.tSeries(:,:,rxSlice,:));
rxTSeries = histoThresh(rxTSeries);
M = mplay(rxTSeries,15);

return