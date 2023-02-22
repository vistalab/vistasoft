function [tSeriesAllSlices,meanImages] = motionCompCorrectMotion(view, ROI, scans, type, typeBaseFrame)
%
%     meanImages = motionCompCorrectMotion(view, [ROI], [scans], [type], [typeBaseFrame])
%
% gb 02/09/05
%
% 

global dataTYPES
curType = viewGet(view,'curDataType');

% Initializes arguments and variables
if ieNotDefined('scans')
    scans = selectScans(view);
end

if ieNotdefined('type')
    type = 'MSE';
end

if ieNotDefined('typeBaseFrame')
    typeBaseFrame = 'Anat';
end

if ieNotDefined('ROI')
    ROI = '';
end

scan = scans(1);

% Computes the error between consecutive frames
switch(upper(type))
    case 'MSE'
        [error,sequences] = motionCompDetectMotionMSE(view,ROI,scans);
    case 'MI'
        [error,sequences] = motionCompDetectMotionMI(view,ROI,scans);
end

% Opens a dialog box to display the first results
qstring = 'Here are the sequences detected:\n';
for index = 1:size(sequences,1);
   qstring = [qstring sprintf('\n     - sequence %d : %d to %d ',index,sequences(index,1),sequences(index,2))];
end

qstring = [qstring sprintf('\n\nWould you like to try to register all of them?')];
button = questdlg(sprintf(qstring),'Correct Motion','Yes','No','default');

if strcmp(button,'No')
   return
end

% Computes the mean image of each sequence
fprintf('Computing the mean images...\n');
nSequences = size(sequences,1);
meanImages = cell(1,nSequences);

for sequenceNum = 1:nSequences
    sequenceIndexes = sequences(sequenceNum,1):sequences(sequenceNum,2);
    meanImages{sequenceNum} = motionCompMeanImage(view,scan,sequenceIndexes);
end

switch (lower(typeBaseFrame))
    case 'anat'
        baseFrame = motionCompResampleAnatomy(view);
        baseFrame = reshape(baseFrame,[1 prod(dataTYPES(curType).scanParams(scan).cropSize) size(baseFrame,3)]);
        fprintf('\nThe reference image is the downsampled anatomy.\n\n');
    otherwise
        [maxSequence, maxSequenceNum] = max(sequences(:,2) - sequences(:,1));   
        baseFrame = shiftdim(meanImages{maxSequenceNum},-1);
        fprintf('\nThe reference image is the mean image of sequence %d.\n\n',maxSequenceNum);
end

baseImage = reshape(baseFrame,[dataTYPES(curType).scanParams(scan).cropSize size(baseFrame,3)]);
tSeriesAllSlices = motionCompLoadImages(view,scan);

for sequenceNum = 1:nSequences

    if ~strcmp(lower(typeBaseFrame),'anat')
        if (sequenceNum ~= maxSequenceNum)
            continue
        end
    end
    
    fprintf('Mapping mean image of sequence %d to the reference image...\n',sequenceNum);
    image = meanImages{sequenceNum};

    image = shiftdim(image,-1);
    
    [coregRotMatrix,image,param] = motionCompMutualInf(view,image,baseFrame,scan);

    image = reshape(image,[dataTYPES(curType).scanParams(scan).cropSize size(image,3)]);
    %[ux,uy,uz] = dtiDeformationFast(baseImage,image);

    fprintf('Applying the deformation field...\n\n');
    sequenceIndexes = sequences(sequenceNum,1):sequences(sequenceNum,2);
    for sequence = sequenceIndexes
        image = tSeriesAllSlices(sequence,:,:);
        image = reshape(image,[dataTYPES(curType).scanParams(scan).cropSize size(image,3)]);
        image = mrSPM_rotateFrame(image, coregRotMatrix, param);
        %image = motionCompApplyTransform(image,ux,uy,uz);
        tSeriesAllSlices(sequence,:,:) = reshape(image,[1 size(image,1)*size(image,2) size(image,3)]); 
    end
    
end