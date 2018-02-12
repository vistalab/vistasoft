function [anat, inplanes] = GetAnatomy(dirName)
% [anat, inplanes] = GetAnatomy(dirName);
%
% Looks at the files in the specified directory and finds all files
% with names of form I.*. Count the number of files that continuously
% run in the sequence I.001, I.002, etc., and have the same non-zero
% size. Load these files, order as a 3D array, and return the array.
%
% inplanes structure containing info about the inplanes
%     FOV
%     fullSize
%     voxelSize
%     nSlices
%     crop
%     cropSize
%
% DBR  6/99

anat = [];

if ~exist(dirName, 'dir'); 
    fprintf(1,'dir does not exist\n')
    return;
end

if(exist(fullfile(dirName,'anat.img'),'file'))
    [anat,mm,hdr] = loadAnalyze(fullfile(dirName,'anat.img'));
    sz = size(anat);
    inplanes.FOV = mm(1)*sz(1);
    inplanes.fullSize = sz(1:2);
    inplanes.voxelSize = mm;
    inplanes.spacing = 0;
    % We already checked hdr.image.slquant==nList, not again -- Junjie
    inplanes.nSlices = sz(3);

    inplanes.examNum = hdr.descrip;
    inplanes.crop = [];
    inplanes.cropSize = [];
else
    
    isDicom=1;
    % first check for DICOM files. These must end in .DCM  (note the case!)
    dS=dir(fullfile(dirName,'*.DCM'));
    nList=length(dS);
    if (nList == 0) % Stanford has lower case endings, UCSF has upper case. Sigh.
        dS=dir(fullfile(dirName,'*.dcm'));
        nList=length(dS);
    end
    if (nList == 0) % If we find no dicom files...
        dS = dir(fullfile(dirName, 'I.*'));
        nList = length(dS);
        if nList == 0; return; end % Nope, nothing here at all
        isDicom = 0;
    end
    
    % Create a subset of files that match our filename criterion: I.nnn or Innn.dcm
    
    nFList = 0;
    fileList = [];
    for iList = 1:nList;
        fName = dS(iList).name;
        if isDicom;
            pat = 'i\d+.dcm'; numstart = 1; numend = 4;
        else
            pat = 'i[.]\d+'; numstart = 2; numend = 0;
        end
        [s f tag] = regexp(lower(fName),pat);
        
        if ~isempty(s);
            seqNo = str2num(fName((s + numstart) : (f - numend)));
            % MA, 11/04/2004: remember the 1st file No that can be > 1:
            if nFList == 0; i1stNo = seqNo; end;
            nFList = nFList + 1;
            fileList{nFList} = fName;
            seqNos(nFList) = seqNo;
        end
    end
    
    % Sort the matching files in ascending numerical order.
    [seqNos, sortInds] = sort(seqNos);
    fileList = fileList(sortInds);
    
    % Check the files for unbroken sequence and matching image size.
    %
    % Put up a status bar if there is more than a single file:
    if nFList > 1
        hBar = mrvWaitbar(0, 'Reading inplane anatomy files');
    end
    % Initialize cell array to hold the images
    tmpImg = cell(1,nFList);
    % Initialize these so we can check that all inplanes are the same
    FOVs = zeros(1,nFList);
    fullSizes = zeros(2,nFList);
    thicknesses = zeros(1,nFList);
    
    % Begin the second pass. Break if sequence or size isn't right.
    for iList=1:nFList
        % MA, 11/04/2001: replaced:
        %if seqNos(iList) ~= iList; break; end
        % we still do not allow gaps, but file numbering can start from any number > 0:
        if seqNos(iList) ~= iList + i1stNo - 1; break; end
        % MA, 11/04/2001: replaced;
        
        [img, hdr] = ReadMRImage(fullfile(dirName, fileList{iList}));
        FOVs(iList) = hdr.image.dfov;
        fullSizes(:,iList) = [hdr.image.imatrix_X; hdr.image.imatrix_Y];
        thicknesses(iList) = hdr.image.slthick;
        tmpImg{iList} = img;
        if nFList > 1
            mrvWaitbar(iList/nFList)
        end
    end
    % Get rid of any status bar
    if nFList > 1
        close(hBar)
    end
    
    
% On some scanners there's this odd thing where the FOVs differ at the 4
% decimal place. This isn't physically meaningful but it means that the
% check on FOV size below will fail. So we just round to the nearest 0.01mm.
FOVs=(round(FOVs*100))/100;


    % Check that all inplanes are the same
    if ~(all(FOVs == FOVs(1)) & all(thicknesses == thicknesses(1)) & ...
            all(fullSizes(1,:) == fullSizes(1,1)) & all(fullSizes(2,:) == fullSizes(2,1)))
        Alert('Inplane anatomy images are different from one another');
        anat = [];
        inplanes = [];
        return;
    end
    
    if (~isDicom) % Can only check GE images for the following thing...
        if hdr.image.slquant ~= nFList
            % Junjie: we shall still continue with this alert, because
            % sometimes I intend to take just part of the inplane images.
            Alert('Not all inplane-anatomy images were found');
            %        anat = [];
            %        inplanes = [];
            %        return;
        end
    end
    inplanes.FOV = FOVs(1);
    inplanes.fullSize = fullSizes(:, 1)';
    inplanes.voxelSize = [FOVs(1)./fullSizes(:, 1)' thicknesses(1)];
    inplanes.spacing = hdr.image.scanspacing;
    % We already checked hdr.image.slquant==nList, not again -- Junjie
    inplanes.nSlices = nFList;

    inplanes.examNum = hdr.exam.ex_no;
    inplanes.crop = [];
    inplanes.cropSize = [];

    anat = zeros([inplanes.fullSize inplanes.nSlices]);
    for iSlice=1:inplanes.nSlices
        anat(:,:,iSlice) = tmpImg{iSlice};
    end

end

