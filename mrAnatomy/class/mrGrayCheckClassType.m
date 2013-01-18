function classType = mrGrayCheckClassType(fileName)
% 
% classType = mrGrayCheckClassType(fileName)
%
% returns 'g' for gray file, 'c' for mrGray class file, 'n' for new
% ITKGray, 'u' for unknown.
% NIFTI class file.
%

[p,f,e] = fileparts(fileName);

switch(lower(e))
    case {'.gray','.grey'}
        classType = 'g';
    case '.class'
        classType = 'c';
    case {'.gz','.nii'}
        classType = 'n';       
    otherwise
        classType = 'u';
end
return; 