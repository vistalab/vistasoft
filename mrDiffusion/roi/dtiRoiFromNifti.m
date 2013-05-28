function roi = dtiRoiFromNifti(nifti,maskValue,outName,outType,binary,save)
% 
% roi = dtiRoiFromNifti([nifti = mrvSelectFile],[maskValue = nonZero],...
%                       [outName=nifti.fname'_maskRoi'],[outType='nifti'],...
%                       [binary=true],[save=true])
% 
% This function will take a nifti and create a (mat or nifti) roi from a
% given maskValue (if no mask value is provided then the non-zero values
% will be used to create the roi) or set of mask values. 
% 
% This funciton can also be used to easily create a mat ROI from a nifti
% ROI.
% 
% INPUTS:
%       nifti       - Path to nifti image.
%       
%       maskValue   - Value in the nifti image you want returned as an
%                     roi.If you wish to use any non-zero value leave this
%                     empty or set to 0. Can also be a list of values.     
%                     E.g., "maskValue = [1024 2024];"
%       
%       outName     - Name to save the roi with. (If you provide an extenison
%                     your roi will be saved with that file type)
%       
%       outType     - 'nifti' or 'mat' [outType='nifti']
% 
%       binary      - Default = true: Only comes into play if outType =
%                     'nifti' and you don't want all non-zero values as
%                     part of the roi. If true then the roi will be a
%                     binary image consisting only of ones and zeros. If
%                     set to false the roi image will retain the original
%                     maskValues with all values not in 'maskValue' set to
%                     zero.
%       
%       save        - Flag where you decide if you want the roi written to
%                     disk. Default = true.
% 
% OUTPUTS: 
%       roi         - ROI structure
% 
% SEE ALSO:
%     dtiRoiNiftiFromMat
%
% WEB RESOURCES:
%       mrvBrowseSVN('dtiRoiFromNifti');
% 
% EXAMPLE USAGE:
%       nifti       = 'CC.nii.gz';
%       maskValue   =  0;       % All nonZero values are used for the mask
%       outName     = 'CC.mat';
%       outType     = 'mat';
%       binary      = true;
%       save        = true;
%       dtiRoiFromNifti(nifti,maskValue,outName,outType,save);
% 
% (C) Stanford University, VISTA Lab [2012] 
% 

% NOTES/IDEAS:
%       * If they don't provide a mask value- we could just take all the
%         non zero voxels and create a mask from that. * DONE
%       * Could accept a set of values for maskValue * DONE
%       * Could make an roi from each individual unique value in the nifti
%         image. *
%       * Check for the existence of the maskValue * DONE
%       * Could rewrite so it's more consistent. Things start to
%         get fuzzy around multiLabel evoking nonZero. --- This is done
%         because the way that non-zero handles the masking process is the
%         same way that we would have to do it for the multiLabel case,
%         thus evoking the nonZero flag in the multiLabel case prevents
%         code redundancy. * DONE


%% Check for nifti file
if notDefined('nifti') || ~exist(nifti,'file')
    nifti = mrvSelectFile('r','*.nii*','Select nifti',pwd);
end

% Strip off the extension for naming later on
[p, f, ~] = fileparts(nifti); 
[p, f, ~] = fileparts(fullfile(p,f));


%% Check mask values and set flags
% Use all non-zero points
if notDefined('maskValue') || maskValue(1) == 0 
    nonZero    = true;
    maskValue  = 'nonZero';
    multiLabel = false;
    fprintf('No mask value provided - using all non-zero points ...'); 

% We have a set of maskValues
elseif numel(maskValue) > 1
    fprintf('Creating ROI from label values: %s ... \n',num2str(maskValue));
    multiLabel = true;
    nonZero    = true;

% We have a singe maskValue 
else 
    %fprintf('Creating ROI from label value: %s ... \n',num2str(maskValue));
    nonZero    = false;
    multiLabel = false;
end


%% Check other input arguments
if notDefined('outName')
    outName = [f '_' num2str(maskValue) '_MaskROI'];
    % Remove spaces from outName
    sp = strfind(outName,' ');
    outName(sp) = '';
end

if notDefined('outType')
    [~ , ~, ext] = fileparts(outName);
    if ~isempty(ext)
        outType = ext;
    else
        outType = 'nifti';
    end
end

% Save by default
if notDefined('save')
    save = true;
end

% Produce a binary image by default. If false then the original mask values
% will be retained in the final ROI. 
if notDefined('binary')
    binary = true;
end


%% Read in the Nifti
ni = niftiRead(nifti);


%% Check for the existence of maskValue in nifti 
% (only applies in ~nonZero and multiLabel case)
% Get unique label values and remove the 0 label index 
allLabels = unique(ni.data);
remove    = find(allLabels==0);
if ~isempty(remove), allLabels(remove) = []; end

if ~nonZero || multiLabel
    for jj = 1:numel(maskValue)
        if ~ismember(maskValue(jj),allLabels)
            error('One or more of your maskValues are not present in the nifti. Check: %s.',num2str(maskValue(jj)));
        end
    end
end


%% MultiLabel case 
% Zero all indices that are not in the maskLabel set of values. 
if multiLabel     
    % Loop over all the labels and set to zero those indices that are not
    % in the maskValue keep list.
    for ii=1:length(allLabels)
        if ~ismember(allLabels(ii),maskValue)
            idx = find(ni.data==allLabels(ii));
            ni.data(idx) = 0;
        end
    end
end


%% Create the ROI from the mask
%#ok<*FNDSB>
% Handle the 'mat' and 'nifti' cases a little differently. 
switch lower(outType)
    case {'mat','.mat'}
        % Mat case does not support binary flag - it's always binary.       
        % Use all non-zero points
        if nonZero || multiLabel
            inds = find(ni.data~=0);
        else
            inds = find(ni.data==maskValue);
        end
        
        % Convert indexed locations to I J K coords
        [I, J, K] = ind2sub(size(ni.data),inds);
        
        % Now convert I J K coords to ACPC
        acpcCoords = mrAnatXformCoords(ni.qto_xyz, [I J K]);
        
        % Add ACPC coords and name into a mrD ROI struct
        roi = dtiNewRoi(outName,'r',acpcCoords);
        [p2, roi.name] = fileparts(outName);
        if ~isempty(p2), p = ''; end
        
        % Save the ROI
        if save
            dtiWriteRoi(roi,fullfile(p,outName));
            fprintf('Saved: %s\n',fullfile(p,outName));
        end
        
    case {'nii','nifti','.nii','.nii.gz'}
        if ischar(maskValue)
                maskValue = str2double(maskValue);
        end
        % Find the indicies not equal to zero and set to 1. 
        if nonZero || multiLabel   
            % Should be binary by default, but in some multiLabel cases you
            % might want to keep the original values.
            if binary
                is = find(ni.data~=0);
                ni.data(is) = 1;
            end
        else 
            % Find those indices that are not = labelVal and set them = 0
            not = find(ni.data~=maskValue);
            ni.data(not) = 0;  
            % Should be binary by default, but in some cases you
            % might want to keep the original values
            if binary
                % Find the indicies = labelVal and set = 1
                is = find(ni.data==maskValue);
                ni.data(is) = 1;
            end
        end
        
        roi = ni; clear ni
        [p2, roi.fname] = fileparts(outName);
        if ~isempty(p2), p = ''; end
            
        % Save out the ROI
        if save
            a = strfind(outName,'.nii.gz');
            if isempty(a)
                outName = [outName '.nii.gz'];
            end
            niftiWrite(roi,fullfile(p,outName));
            fprintf('Saved: %s\n',fullfile(p,outName));
        end
end

return


