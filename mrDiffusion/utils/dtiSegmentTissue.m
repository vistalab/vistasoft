function outNi = dtiSegmentTissue(dataDir,outFile)
%
% outNi = dtiSegmentTissue(dataDir,[outFile=fullfile(dataDir,'tissueClass.nii.gz'))
%
% Set outFile=false to not save the results in a file.
% 
% E.g.:
% subDir{ii} = pwd;
% dd = fullfile(subDir{ii},'dti40','bin');
% ni = dtiSegmentTissue(dd);
% showMontage(ni.data)
%
% 2008.10.15 RFD: wrote it.

if(~exist('outFile','var')||isempty(outFile))
    outFile = fullfile(dataDir,'tissueClass.nii.gz');
elseif(islogical(outFile) && ~outFile)
    outFile = [];
end

b0 = niftiRead(fullfile(dataDir,'b0.nii.gz'));
bm = niftiRead(fullfile(dataDir,'brainMask.nii.gz'));
% the brainMask file in the bin dir is based on the b0 and can include
% extra stuff, like the eyes. So, we'll combine it with a bet mask to clean
% it up.
[betMask,checkSlices] = mrAnatExtractBrain(fullfile(dataDir,'b0.nii.gz'));
bm = bm.data&betMask;
bmEdge = ~imerode(bm,strel('disk',2)) & bm;

[wm, gm, csf] = mrAnatSpmSegment(b0.data, b0.qto_xyz, 'mniepi');

% We want a mask that is generous on the gm, since FascTrac will allow
% voxels flagged as gm to contain wm paths if the diffusion data warrant
% it. So, we will give the gm mask priority over wm and csf.
classIm = zeros(size(wm),'uint8');
classIm(csf>0.5*255) = 3;
classIm(wm>0.5*255) = 2;
classIm(gm>0.5*255) = 1;
classIm(~bm) = 0;
% add an extra layer of gm at the brain edge to be sure it is closed
classIm(bmEdge) = 1;
% Iteratively fill 'holes' with the median of the neighbors
for(ii=1:2)
    filler = mrAnatMedianFilter(classIm);
    holes = classIm==0 & filler~=0;
    classIm(holes) = filler(holes);
end

outNi = niftiGetStruct(classIm, b0.qto_xyz, 1, 'gm=1,wm=3,csf=3');
if(~isempty(outFile))
    % save it as a nifti file
    outNi.fname = outFile;
    writeFileNifti(outNi);
end

return;

[s,sc] = findSubjects('/biac3/wandell4/data/reading_longitude/dti_y4/*','dti06');
for(ii=1:numel(s))
    dd = fullfile(fileparts(s{ii}),'bin');
    ni = dtiSegmentTissue(dd);
    showMontage(ni.data,[],[],[],[],87);
    set(87,'name',sc{ii});
end




