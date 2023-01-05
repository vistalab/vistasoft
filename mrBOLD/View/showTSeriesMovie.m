function showTSeriesMovie(view,nTimes)
% 
% showTSeriesMovie(view,[nTimes])
%
% Displays a previously computed tseries movie in the graph window.
%
% nTimes: default = 2.
%
% djh, 3/2001

if ~exist('nTimes','var')
  nTimes = 2;
end

if ~isfield(view.ui,'movie') | isempty(view.ui.movie)
    myErrorDlg('showFunctionalMovie: make the movie first before trying to show it');
end

selectGraphWin; clf;
scan = view.ui.movie.scan;
slice = view.ui.movie.slice;
set(gcf,'Name',['tSeries movie, scan ',num2str(scan),', slice ',num2str(slice)]);
set(gca,'Position',[0 0 1 1]);
axis image; axis off;
movie(view.ui.movie.movie,nTimes);
