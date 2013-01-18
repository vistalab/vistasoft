function y = er_ldtfile(varargin)
%
% y = er_ldtfile(tfilename)
% y = er_ldtfile(tfilename1,tfilename2,...,tfilenameN)
%
% Loads a mrVista tSeries file given the full path
% and name of the tSeries. (Note that the name is generally 
% 'tSeries.mat' and the identification of which scan/slice 
% it represents is determined by the path.)
%
% If multiple tfiles are specified, then
% another dimension is added to y at the end to indicate
% the file from which it came.  Data from all files must
% have the same dimensionality.
%
% $Id: er_ldtfile.m,v 1.7 2005/05/11 21:34:32 sayres Exp $
%
% 06/18/03 ras: updated from fmri_ldbfile in an attempt to integrate
% fs-fast functionality into mrLoadRet.
%
% See also: fmri_svbile()
global mrSESSION; 

y = [];

if(nargin == 0) 
    fprintf(2,'USAGE: er_ldtfile(tFileName)');
    qoe;
    return;
end

if( length(varargin) == 1)
    tFileList = varargin{1};
    nRuns = size(tFileList,1);
else
    nRuns = length(varargin);
    tFileList = '';
    for r = 1:nRuns,
        tFileList = strvcat(tFileList,varargin{r});
    end
end

% test if this is an inplane tSeries
% (have to do this by path) -- if it
% is, we'll reshape it below:
if findstr('inplane',lower(tFileList(1,:)))==1
    ipFlag = 1;
else
    ipFlag = 0;
end

for r = 1:nRuns,
    
    tFileName = deblank(tFileList(r,:));
    
    %%% load the tSeries %%%
    tmp = load(tFileName);
    z = tmp.tSeries;
    
    %%% Reshape into image dimensions         %%%
    nD = size(z,1);
    
    if ipFlag==1
        if ~isempty(mrSESSION)
            nR = mrSESSION.functionals(1).cropSize(1);
            nC = mrSESSION.functionals(1).cropSize(2);
        else
            % guess that it's square
            nR = sqrt(size(z,2))
            nC = nR;
            
            if mod(nR,1)~=0
                fprintf('Error: tSeries size doesn''t appear to be square.');
                fprintf(' This is okay if you have the mrSESSION struct w/ crop info in your workspace memory.');
                qoe;
                return;
            end
        end
        % reshape if it makes sense
        % (for volume, maybe flat views, it may not)
        if nD*nR*nC==length(z)
            z = reshape(z,[nD nR nC]);
        end
        
    end
    
    %%% Permute into rows x cols x time frames form %%%
    z = permute(z,[2 3 1]);
    
    if(size(z,1) == 1 & size(z,3) == 1)
        y(:,:,r) = z;
    else
        y(:,:,:,r) = z;
    end
    
end

return;

%%% y now has size(y) = [nR nC nD nRuns] %%%

