function view=fsl_doFullMLRMotionCorrect(view,scansToProcess,newDataTypeName,forceOverwriteFlag)
% view=fsl_doFullMotionCorrect(view,scansToProcess,newDataTypeName,forceOverwriteFlag)
% PURPOSE: Motion corrects scans (both within and across scans) and replaces the time series in the
% specified dataTYPE. If no dataTYPE is given, 
% the routine defaults to Original i.e. the original time series
% are replaced. 
% Along the way, it makes 4D analyze files from the original datasets.
% If you want to revert, you can use fsl_analyze2MLR to regenerate time
% series data from the original 4d analyze files.
% See also fsl_preprocessMLRTSeries, fsl_motionCorrectMLR
% e.g. 
% fsl_doWithinScanMLRMotionCorrect(INPLANE{1},1,'MC_Original')
% ARW 120604
% $Author: wade $
% $Date: 2006/03/08 01:33:08 $
mrGlobals;

if (ieNotDefined('view'))
    view=getSelectedInplane;
end
if (ieNotDefined('forceOverWriteFlag'))
    forceOverwriteFlag=0;
end


if (view.curDataType~=1) % We enforce this right now but not in later versions
    error('The data type must be Original (dataTYPE == 1)');
end

if (ieNotDefined('scansToProcess'))
    disp('Select scans to process');
    scansToProcess=selectScans(view,'Scans to process');
end

% First, do the within scan mc
view=fsl_motionCorrectMLR(view,scansToProcess); % Do the motion correction

% Now we have the 4d analyze files in the 'Original' directory.

% Check to see where the output is going. If it's going back to 'Original
if ((~exist('newDataTypeName','var') | (isempty(newDataTypeName)))  & (~forceOverwriteFlag))
    newDataTypeName='Original';
    if(~strcmp(questdlg('This will overwrite stuff in the original tSeries. Proceed?','Warning!','Yes','No','No'),'Yes'))
        return;
    end
end % Note - if you explicity specify 'Original' as the output dataTYPE then you are taken at your word. 


view=fsl_analyze2MLR(view,scansToProcess,2,newDataTypeName);


