function view=fsl_doAcrossScanMLRMotionCorrect(view,scansToProcess,newDataTypeName,referenceScanNumber)
% view=fsl_doAcrossScanMLRMotionCorrect(view,scansToProcess,newDataTypeName,forceOverwriteFlag)
% PURPOSE: 
% Does an across-scan motion correction for the selected scans using fsl
% 1: Computes the mean of each scan using avwmath -Tmean
%
% 2: Uses flirt to get a xform matrix aligning all scans to the reference
% scan
%
% 3: Applies that xform to the 4d analyze data using applyxfm4d
%
% ARW 120604
% $Author: wade $
% $Date: 2006/07/28 19:23:42 $
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
view=fsl_motionCorrectMLR(view,scansToProcess); % Do the motion correction

% Check to see where the output is going. If it's going back to 'Original
if ((~exist('newDataTypeName','var') | (isempty(newDataTypeName)))  & (~forceOverwriteFlag))
    newDataTypeName='Original';
    if(~strcmp(questdlg('This will overwrite stuff in the original tSeries. Proceed?','Warning!','Yes','No','No'),'Yes'))
        return;
    end
end % Note - if you explicity specify 'Original' as the output dataTYPE then you are taken at your word. 


view=fsl_analyze2MLR(view,scansToProcess,2,newDataTypeName);


