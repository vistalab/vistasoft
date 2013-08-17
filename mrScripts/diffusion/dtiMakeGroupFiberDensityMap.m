function dtiMakeGroupFiberDensityMap(fgName,fibPath,endptFlag,dilate,subSpace,outName)

%% Eample
%example: dtiMakeGroupFiberDensityMap('L_Arcuate.mat','/fibers/IPSproject/arcuate', 1,1,1,'/white/u2/jyeatman/data/ArcuateMap')
%
%fgName is the fiber group name
%
%fibPath is the path to the fiber group from the subject's base directory
%
%endptFlag: 1 if you want the map to be made just for fiber endpoints and
%0 if you want it made for the full fiber group.  If you want to display on
%the cortical surface set endptFlag=1
%
%dilate: 1 if you want each subjects fiber group to be smoothed and dilated
%before making the group map. 2 if you want each subjects fiber group to be
%dilated and smoothed twice before making the group map.  This creates more
%overlap and is more analagous to the SPM methodology of smoothing the heck
%out of everything
%
%subSpace: 1 if you want the map to be output in the native space of a
%single subject 0 if you want it in MNI space.  YOu can set which subject
%below
%
%outname: the output name as a string including the path to where you want
%it save for example ''/biac3/wandell4/data/reading_longitude/dti_adults/rb080930/dti06trilin/fibers/ArcuatMap'

%% get subject directory structure
[subList,subCodes,subDirs,subLetters] = findSubjects;
%count how many subjects get added into analysis
numSubs=0;

%template to be used as a reference image from which we will construct our group map.  This reference
%image is modified rather than creating a nifti from scratch
tdir = fullfile(fileparts(which('mrDiffusion.m')), 'templates');
if subSpace==1
    ref=niftiRead(fullfile('/biac3/wandell4/data/reading_longitude/dti_adults/rfd070508/dti06trilinrt','bin','b0.nii.gz'));
else
    refImage = fullfile(tdir,'MNI_EPI.nii.gz');
    ref = niftiRead(refImage);
end

%% If you want the map output in the native space of a single supbject then
%put the path to that subjects dt6 file here.  This is useful if you want
%to visualize results on a 3d mesh.  Otherwise the map will be saved in MNI
%space
if subSpace==1
    subDt6=dtiLoadDt6('/biac3/wandell4/data/reading_longitude/dti_adults/rb080930/dti06trilin/dt6');
    [snSub, defSub]=dtiComputeDtToMNItransform(subDt6);
end
%% Loop through subjects
for ii=1:length(subCodes)
    fibDir=fullfile(subDirs{ii},fibPath);
    fibFile=fullfile(fibDir, fgName);
    if exist(fibFile,'file')
        disp(subCodes{ii});
        numSubs=numSubs+1
        dt=dtiLoadDt6(subList{ii});
        fg=dtiReadFibers(fibFile);
        %fg=mtrImportFibers(fibFile, dt.xformToAcpc);
        if ~isempty(fg.fibers)

            %compute MNI transformation

            [sn, def]=dtiComputeDtToMNItransform(dt);

            %Normalize fibers

            fg = dtiXformFiberCoords(fg, def);

            if subSpace==1
                fg = dtiXformFiberCoords(fg, snSub);
                fg = dtiXformFiberCoords(fg, subDt6.xformToAcpc);
            end

            %convert fibers to ROI if endpoints flag = 0 then do for the whole
            %fiber group.  if ==1 then only for fiber endpoints
            if endptFlag==0

                roi = dtiNewRoi([fg.name,'_fiberROI'], fg.colorRgb./255, unique(round(horzcat(fg.fibers{:}))','rows'));

            elseif endptFlag==1
                for kk=1:length(fg.fibers)
                    endpts(:,kk)=fg.fibers{kk}(:,end);
                    startpts(:,kk)=fg.fibers{kk}(:,1);
                end
                roi = dtiNewRoi([fg.name,'_fiberROI'], fg.colorRgb./255, unique(round(horzcat(endpts,startpts))','rows'));
                clear startpts endpts;
            end
            %get rid of an NaNs
            roi.coords=roi.coords(~isnan(roi.coords(:,1)),:);
            %Clean ROI if desired
            if dilate==1
                roi=dtiRoiClean(roi,3,{'dilate' 'fillHoles'});
            end
            if dilate==2
                roi=dtiRoiClean(roi,3,{'dilate' 'fillHoles'});
                roi=dtiRoiClean(roi,4,'dilate');
            end
            if dilate==3
                roi=dtiRoiClean(roi,3,{'dilate' 'fillHoles'});
                roi=dtiRoiClean(roi,4,'dilate');
                roi=dtiRoiClean(roi,5,'dilate');
            end

            %% Convert ROI to nifti image in MNI spae

            % transform ROI coords to MNI image space
            c = mrAnatXformCoords(ref.qto_ijk, roi.coords);
            c = round(c);
            roiIm = ref;
            roiIm.data = zeros(size(roiIm.data),'uint8');
            roiIm.data(sub2ind(size(roiIm.data), c(:,1), c(:,2), c(:,3))) = 1;
            %roiIm.fname = strcat(outFile,'.nii.gz');

            %% make a group combintion of all the images
            if ~exist('groupIm','var')
                groupIm=roiIm.data;
            else
                groupIm=groupIm+roiIm.data;
            end
        else
            fprintf('\n%s does not exist for subject %s\n',fgName,subCodes{ii})
            continue
        end

    end
end
%% Write group file
roiIm.data=groupIm;
roiIm.scl_slope=1;
roiIm.fname = [outName '.nii.gz'];
writeFileNifti(roiIm);

%% if you want to write thresholded maps for any reason
% roiIm.data=uint8(thresh40);
% roiIm.fname = fullfile(outDir,[outName  '55thresh40.nii.gz']);
% writeFileNifti(roiIm);
%
% roiIm.data=uint8(thresh45);
% roiIm.fname = fullfile(outDir,[outName '55thresh45.nii.gz']);
% writeFileNifti(roiIm);
%
% roiIm.data=uint8(halfSubs);
% roiIm.fname = fullfile(outDir,[outName  '55HalfSubs.nii.gz']);
% writeFileNifti(roiIm);


