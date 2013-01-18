function outData=getTSeriesInAnalyzeForm(view,examNum)
% outData=getTSeriesInAnalyzeForm(view,scanNum)
%
% view is INPLANE (mrLoadRet25) or INPLANE{1} (mrLoadRet3).
%
% Start of procedure to generate SPM-like maps for our data sets.
% First step is to generate 'v' or 'volume' files to feed into SPM.
% THese are like our tSeries files except that they are organised as 
% a single file for each volume at a particular TR. In other words, if there are
% 16 inplanes, 80 TRs and an inplane voxel size of 90*100, there will be
% 80 'v' files (called v[examNam].000 to .079  (note the zero-referencing)
% and each file will be 90*100*16 elements in size (and 16 bits deep?)
% ARW 10/16/01
% JL 9/17/04 updated to be compatible for both mrLoadRet25 and mrLoadRet3

mrGlobals; % Needs mrSESSION information

if ~strcmp(view.name(1:7),'INPLANE');
    error('Input view is not INPLANE');
end

% JL: insert the code for mrLoadRet3
if isfield(mrSESSION,'mrLoadRetVersion');
    if mrSESSION.mrLoadRetVersion >= 3;
        if (~exist('examNum','var')) || isempty(examNum);
            examNum = viewGet(view,'curScan');
        end
        for curSlice = dataTYPES(viewGet(view,'curdatatype')).scanParams(examNum).slices;
            tSeries = loadtSeries(view,examNum,curSlice);
            outData(:,:,:,curSlice) = reshape(tSeries,[dataTYPES(viewGet(view,'curdatatype')).scanParams(examNum).nFrames, dataTYPES(viewGet(view,'curdatatype')).scanParams(examNum).cropSize]);
        end
        return
    end
end

% These should all be sessionGet() calls.  These are all from the
% functionals.
inplaneSize= mrSESSION.functionals(examNum).cropSize;
nFrames    = mrSESSION.functionals(examNum).nFrames;

% 
slices     = mrSESSION.functionals(examNum).slices;
nSlices    = length(slices);
outData=zeros(nFrames,inplaneSize(1),inplaneSize(2),nSlices);

for ii=1:nSlices
    % It's important (for statistical reasons) not to interpolate the data when
    % they come in.
    thisSlice = slices(ii);
    tSeries = loadtSeries(view,examNum,thisSlice);
    a=reshape(tSeries,[nFrames,inplaneSize(1),inplaneSize(2)]);
    outData(:,:,:,ii)=a;
end

return
