electrodeSize = 3;
electrodeNi = niftiRead('t1_class_gray_electrodeCenters.nii.gz'); %'Segmentations/ct_seg_electrodes.nii.gz');
classNi = niftiRead('t1_class.nii.gz'); %'Segmentations/t1_average_manualSeg.nii.gz');
labels = mrGrayReadLabels('t1_class_gray_electrodeCenters.lbl'); %'Segmentations/ct_seg_electrodes.lbl');
t1Ni = niftiRead('t1_aligned.nii.gz'); %'t1_average.nii.gz');
% Force the xform to be the same as the t1. (ITKGray doesn't set the xform
% correctly when you create a new segmentation.)
electrodeNi = niftiSetQto(electrodeNi,t1Ni.qto_xyz);
classNi = niftiSetQto(classNi,t1Ni.qto_xyz);

tFile = which('MNI_T1.nii.gz');
[sn, Vt, def] = mrAnatComputeSpmSpatialNorm(t1Ni.data, t1Ni.qto_xyz, tFile);

% To get MNI coords for an ac-pc coord:
% mniCoord = mrAnatXformCoords(def,acpcCoord)
% Given an image coord, use:
% mniCoord = mrAnatXformCoords(def,mrAnatXformCoords(t1Ni.qto_xyz,imgCoord))
elecInds = strmatch('electrodeCenters', {labels(:).name});
%elecStemInds = strmatch('ElectrodeStem',{labels(:).name});
%elecInds = elecInds(elecInds~=elecStemInds);
nElectrodes = numel(elecInds);
clear et;
for(ii=1:nElectrodes)
    et(ii).name = labels(elecInds(ii)).name;
    tmpIm = electrodeNi.data==labels(elecInds(ii)).index;
    inds = find(tmpIm);
    if(~isempty(inds))
        [x,y,z] = ind2sub(size(tmpIm),inds);
    end
    et(ii).acpcCoords = mrAnatXformCoords(electrodeNi.qto_xyz,[x,y,z]);
    et(ii).mniCoords = mrAnatXformCoords(def,et(ii).acpcCoords);
    for(jj=1:size(et(ii).mniCoords,1))
        aal = strtrim(dtiGetBrainLabel(et(ii).mniCoords(jj,:), 'MNI_AAL'));
        brd = strtrim(dtiGetBrainLabel(et(ii).mniCoords(jj,:), 'MNI_Brodmann'));
        wma = strtrim(dtiGetBrainLabel(et(ii).mniCoords(jj,:), 'MNI_JHU_WM'));
        et(ii).label{jj} = strrep([aal ', ' brd ', ' wma],'none, ','');
        et(ii).label{jj} = strrep(et(ii).label{jj},', none','');
    end
end

fid = fopen('electrodeList.txt','w');
for(ii=1:nElectrodes)
    for(jj=1:size(et(ii).mniCoords,1))
        mni = et(ii).mniCoords(jj,:);
        tal = round(mni2tal(mni));
        fprintf(fid,'%s-%d: MNI=[%d,%d,%d], Talairach=[%d,%d,%d], label=%s\n',...
            et(ii).name, jj, mni(1),mni(2),mni(3), tal(1),tal(2),tal(3), et(ii).label{jj});
    end
    fprintf(fid,'\n');
end
fclose(fid);

