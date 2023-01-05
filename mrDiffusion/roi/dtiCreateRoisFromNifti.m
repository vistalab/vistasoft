function roisArray=dtiCreateRoisFromNifti(niftiFile)

%Create an array of ROIs corresponding to unique values in niftiFile.
%niftiFile should contain integer values labeling the voxels from the list
%of ROIs. 

%ER 11/2009 wrote it 

roiNii = niftiRead(niftiFile);

        % Find all unique, non-zero indices, each distinct index will be a
        % mask for a distinct ROI
        roiNii.data(isnan(roiNii.data))=0;
        roisToMake=unique(uint8(roiNii.data));
        roisToMake=roisToMake(roisToMake~=0);
        
        % For each distinct index, create a distinct ROI
        for jj=1:length(roisToMake)
        
            thisRoi = find(roiNii.data==roisToMake(jj));
            [x1,y1,z1] = ind2sub(size(roiNii.data), thisRoi);
            roisArray(jj) = dtiNewRoi([roiNii.fname '_' num2str(roisToMake(jj))], rand(1, 3));
            roisArray(jj).coords = mrAnatXformCoords(roiNii.qto_xyz, [x1,y1,z1]);
            roisArray(jj).name=[roiNii.fname '_' num2str(jj)]; 
            
        end
        if ~exist('roisArray', 'var')
            roisArray=[];
        end
       
