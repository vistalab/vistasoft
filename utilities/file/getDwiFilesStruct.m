function dw = getDwiFilesStruct(path)
% 
%  [dw] = getDwiFilesStruct(path)
% 
% Given a path, returns a stucture containing the full path to any and all
% diffusion files (nifti, bvec, bvals) it finds. The size of the structre
% will be equal to the number of unique prefixes found in the directory.
% 
% The files must have the same prefix: E.g, 4534_14_1.nii.gz
%                                           4534_14_1.bvec
%                                           4534_14_1.bval
%
% INPUT:
%    path - Full path to a directroy containing any number of subfolders
%           with diffusion data processed by nims.
% 
% OUTPUT:
%   dw{n}  - where n is equal to number of unique prefixes found in the
%            directory with the following fields: 
%                                                 d{n}.nifti 
%                                                 d{n}.bvec 
%                                                 d{n}.bval
%                                                 d{n}.series 
%                                                 d{n}.bvalue 
%                                                 d{n}.directions
% 
% EXAMPLE USAGE:
% dw = getDwiFilesStruct('/biac4/wandell/data/westonhavens/upload/testlab/20130509_1152_4534');
%       
%     >> dw
% 
%     dw = 
% 
%         [1x1 struct]    [1x1 struct] 
% 
%     >> dw{1}
% 
%       ans = 
% 
%         nifti: '/biac4/wandell/data/westonhavens/upload/testlab/20130509_1152_4534/4534_14_1_DTI_2mm_30dir_2x_b1000/4534_14_1.nii.gz'
%          bvec: '/biac4/wandell/data/westonhavens/upload/testlab/20130509_1152_4534/4534_14_1_DTI_2mm_30dir_2x_b1000/4534_14_1.bvec'
%          bval: '/biac4/wandell/data/westonhavens/upload/testlab/20130509_1152_4534/4534_14_1_DTI_2mm_30dir_2x_b1000/4534_14_1.bval'
%        series: '4534_14_1'
%        bvalue: 1000
%    directions: 30
% 
% 
% (C) Stanford University, Vista Lab [2014]
% 


%% Input check
if notDefined('path') || ~exist(path,'dir')
    path = uigetdir(pwd,'Choose path');
    if path == 0; dw = []; clear path; return; end
end



%% Get a list all the relevant files
tn  = tempname;
cmd = ['find ' path ' -follow -type f -name "*.nii.gz" -o -name "*.bvec" -o -name ".bval" | tee ' tn];

[status, result] = system(cmd);

if status ~= 0
    error('There was a problem finding files.');
end

% WORK HERE - if tn is empty then we need to not follow through

% niFiles will now have a full-path list of all relevant files
if ~isempty(result)
    theFiles = readFileList(tn);
else
    fprintf('[%s]: No diffusion nifti files found.\n', mfilename); 
    dw = []; 
    return
end



%% Get the data based on which has an associated bvec file.
bfile = {};
base  = {};
c = 1;

for jj = 1:length(theFiles)
    
    if (strfind(theFiles{jj},'.bvec'))
        [base{c}, bfile{c}] = fileparts(theFiles{jj});
        c = c+1;
    end
    
end



%% Get the diffusion data into dw{} with d{n}.nifti d{n}.bvec d{n}.bval
dw = {};
for kk = 1:numel(bfile)

    dw{kk}.nifti = fullfile(base{kk},[bfile{kk} '.nii.gz']);
    dw{kk}.bvec  = fullfile(base{kk},[bfile{kk} '.bvec']);
    dw{kk}.bval  = fullfile(base{kk},[bfile{kk} '.bval']);
    
    dw{kk}.series     = bfile{kk};
    dw{kk}.bvalue     = getbvalue(dw{kk}.bval);
    dw{kk}.directions = getdirections(dw{kk}.bvec);

end


if isempty(dw)
    fprintf('[%s] - Diffusion data not found in: %s\n', mfilename, path);
	elseif numel(dw) == 1
    	fprintf('[%s]: Diffusion data found!\n', mfilename); 
	elseif numel(dw) > 1
    	fprintf('[%s]: Found %.0f Diffusion data sets!\n',mfilename,numel(dw));
end

for x = 1:numel(dw)
	fprintf('dw %s: \n\t%s\n\t%s\n\t%s\n',num2str(x),dw{x}.nifti,dw{x}.bvec,dw{x}.bval);
end

return
%%


%%%% Get the bvalue
function bvalue = getbvalue(bval)
    b = dlmread(bval);
    % Take all nonzero bvalues and take the mode as the bvalue
    bvalue = mode(nonzeros(b));
return



%%%% Get the number of directions
function directions = getdirections(bvec)
    d = dlmread(bvec);
    % Sum each column and take the number of elements of all nonzero sums
    % as the number of directions
    directions = numel(nonzeros(sum(d)));
return






