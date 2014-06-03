function [results] = niftiCheckIsEqual(nifti1,nifti2,quiet)

%
% results = niftiCheckIsEqual(nifti1,nifti2)
% 
% DESCRIPTION 
%   Run isequal on a pair of nifti files field by field. 
% 
% USAGE 
%   results = niftiCheckIsEqual(nifti1,nifti2)
% 
% INPUT
%   nifti1  - The filename/path or structure of a niftifile
% 
% OUTPUT
%   results - A structure containing the following fields
%           - .allequal >> boolean where 1 == all equal and 0 == not.
%           - .equal    >> fieldnames of equal-fields
%           - .notequal >> filednames of unequal-fields
%           - .nonfield >> fieldnames that are absent in at least one
%                          nifti.
% 
%#ok<*AGROW>


%% Handle inputs

results = {};

if notDefined('nifti1')
    nifti1 = mrvSelectFile('r','*.nii*','Select first nifti file',pwd);
    if isnumeric(nifti1) || isempty(nifti1)
        return
    end
end

if ~isstruct(nifti1)
    n1 = niftiRead(nifti1);
else
    n1 = nifti1;
end

if notDefined('nifti2')
    nifti2 = mrvSelectFile('r','*.nii*','Select second nifti file',pwd);
    if isnumeric(nifti2) || isempty(nifti2)
        return
    end
end

if ~isstruct(nifti2)
    n2 = niftiRead(nifti2);
else
    n2 = nifti2;
end

if notDefined('quiet')
    quiet = 0; 
end


%% Compare nifti fields

fields1 = fieldnames(n1);
fields2 = fieldnames(n2);

if ~isequal(fields1,fields2)
    warning('Nifti files do not have the same fields.');
    allfields = unique(sort(horzcat(fields1,fields2)));
else
    allfields = fields1;
end


% Initialize the return structure fields
notequal = {};
equal    = {};
nonfield = {};


% Go over the fields and compare
for ii = 1:numel(allfields)
    if isfield(n1, allfields{ii}) && isfield(n2, allfields{ii})
        if isequal(n1.(allfields{ii}),n2.(allfields{ii}))
            equal{end+1} = allfields{ii};
        else
            notequal{end+1} = allfields{ii};
        end
    else
       nonfield{end+1} = allfields{ii}; 
    end
end


%% Display the results

if ~quiet   
    if ~isempty(nonfield)
        fprintf('\nNON-EXISTING FIELDS:\n');
        for jj = 1:numel(nonfield)
            fprintf('\t%s \n',nonfield{jj});
        end
    end
    
    if ~isempty(equal)
        fprintf('\nEQUAL FIELDS:\n');
        for jj = 1:numel(equal)
            fprintf('\t%s \n',equal{jj});
        end
    end
    
    if ~isempty(notequal)
        fprintf('\nNON-EQUAL FIELDS:\n');
        for jj = 1:numel(notequal)
            fprintf('\t%s \n',notequal{jj});
        end
        
        fprintf('\n:::: NON-EQUAL DETAILED OUTPUT ::::\n')
        for kk = 1:numel(notequal)
            disp(['>>> ' notequal{kk} ' <<<']);
            
            % Do not display the data field
            if ~strcmpi(notequal{kk},'data')
                disp(n1.(notequal{kk}));
                disp(n2.(notequal{kk}));
                disp('----');
                
            else disp(' Data field is not equal');
                disp(' ----')
            end
        end
    else
        disp('ALL FIELDS ARE EQUAL');
    end
end


%% Return the results

results.allequal = isequal(n1,n2);
results.equal    = equal;
results.notequal = notequal; 
results.nonfield = nonfield;


return
