function [status]=mrLoadRetAnat2SPM(fileRoot)
%function [status]=mrLoadRetAnat2SPM(fileRoot)

global INPLANE;

if (~exist('INPLANE','var'))
    error('INPLANE Structure must exist');
end
if (isempty(INPLANE.anat))
    error('INPLANE.anat must contain data: select view->croppedAnatomy in mrLoadRet to get the anatomies up');
end
if (~exist('fileRoot','var'))
    error('You must enter a file root: e.g. //gwyn/u1/mri/sampleSet/012345/vSPM_test');
end


outDat=INPLANE.anat;

% This is a script to dump out the current INPLANE.anat data in Analyse format so that you can load it in to SPM
% We make some effort to ensure that it conforms to the expected orientation of SPM data
% In the INPLANE structure it's stored as x*y*nSlices
% Now we can't guarantee that we're going to get the orientation right (becasue we're not yet at the stage where we can align funcitonal data to the 
% SPM template) but we can try to at least get the nSlices direction right so that the 'coronal' views more or less line up for mrLoadRet and SPM
                            
% Now, just call writeAnatFileSet
fileVector=writeAnatFileSet(outDat,fileRoot);


