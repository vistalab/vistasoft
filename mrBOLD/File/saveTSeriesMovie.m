function saveTSeriesMovie(view,baseFileName,format)
% 
% showTSeriesMovie(view,baseFileName,[format])
%
% Saves a previously computed tseries movie.
%
% format: default = 'avi'
%
% HISTORY:
%   2003.12.11 RFD: wrote it.
%

if ~isfield(view.ui,'movie') | isempty(view.ui.movie)
    myErrorDlg('saveTSeriesMovie: make the movie first before trying to save it');
end

if(~exist('baseFileName','var') | isempty(baseFileName))
    [f,p] = uiputfile('*','Select base file name...');
    baseFileName = fullfile(p,f);
end
if(~exist('format','var') | isempty(format))
    format='png';
end

switch(lower(format))
    case 'avi'
        movie2avi(view.ui.movie.movie, [baseFileName '.avi']);
    case 'jpeg'
        for(ii=1:length(view.ui.movie.movie))
            fname = sprintf('%s_%04d.jpg', baseFileName, ii);
            imwrite(view.ui.movie.movie(ii).cdata, fname, ...
                'jpeg', 'Compression', 85);
        end
    case 'png'
        for(ii=1:length(view.ui.movie.movie))
            fname = sprintf('%s_%04d.png', baseFileName, ii);
            imwrite(view.ui.movie.movie(ii).cdata, fname, ...
                'png');
        end
    otherwise
        error('Unknown format.');
end
