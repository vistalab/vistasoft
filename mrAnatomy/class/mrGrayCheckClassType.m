function classType = mrGrayCheckClassType(fileName)
% 
% classType = mrGrayCheckClassType(fileName)
%
% returns 'g' for gray file, 'c' for mrGray class file, 'n' for new
% ITKGray, 'u' for unknown.
% NIFTI class file.
%

[~,~,e] = fileparts(fileName);

switch(lower(e))
    case {'.gray','.grey'}
        classType = 'mrGray';
    case '.class'
        classType = 'mrGray';
    case {'.gz','.nii'}
        classType = 'n';       
    otherwise
        classType = 'u';
end


if strcmpi(classType, 'mrGray')
    error('Vistasoft no longer supports mrGray Gray and Class files. Please convert to nifti.')
end

return;