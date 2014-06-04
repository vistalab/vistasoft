function [results] = niftiCheckIsEqual(nifti1,nifti2,quiet)
%
% results = niftiCheckIsEqual([nifti1],[nifti2],[quiet])
% 
% 
% DESCRIPTION: 
%   Run 'isequal' on a pair of nifti files, field by field. If ~ quiet print
%   a summary of equal and ~equal values do the command window.
% 
% USAGE:
%   results = niftiCheckIsEqual(nifti1,nifti2)
% 
% INPUT:
%   nifti1  - The filename/path or structure of a niftifile
%   nifti2  - The filename/path or structure of a niftifile
%   quiet   - Supress output to command window. Only field names are 
%             returned.
% 
% OUTPUT:
%   results - A structure containing the following fields
%           - .allequal >> boolean where 1 == all equal and 0 == not.
%           - .equal    >> fieldnames of equal-fields
%           - .notequal >> filednames of unequal-fields
%           - .nonfield >> fieldnames that are absent in at least one
%                          nifti.
% 
%
% (C) Stanford University, VISTA 2014 [ lmperry@stanford.edu ]
%
%
%#ok<*AGROW>


%% HANDLE INPUTS

results = {};

if notDefined('nifti1')
    nifti1 = mrvSelectFile('r','*.nii*','Select first nifti file',pwd);
    if isnumeric(nifti1) || isempty(nifti1)
        return
    end
end


if notDefined('nifti2')
    nifti2 = mrvSelectFile('r','*.nii*','Select second nifti file',pwd);
    if isnumeric(nifti2) || isempty(nifti2)
        return
    end
end


% Read the nifti files if not passed in as structs
if ~isstruct(nifti1)
    n1 = niftiRead(nifti1);
else
    n1 = nifti1;
end

if ~isstruct(nifti2)
    n2 = niftiRead(nifti2);
else
    n2 = nifti2;
end


% Quiet param will cause window output to be supressed
if notDefined('quiet')
    quiet = 0; 
end

if ~quiet
    fprintf('Running %s ... \n\tNifti 1 = %s\n\tNifti 2 = %s\n',mfilename,n1.fname,n2.fname);
end


%% COMPARE NIFTI FIELDS

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


%% DISPLAY THE RESULTS

if ~quiet   
    if ~isempty(nonfield)
        fprintf('\nNON-EXISTING FIELDS:\n');
        for jj = 1:numel(nonfield)
            fprintf('\t%s \n',nonfield{jj});
        end
    end
    
    % Display results for equal fields
    if ~isempty(equal)
        fprintf('\nEQUAL FIELDS:\n');
        for jj = 1:numel(equal)
            fprintf('\t%s \n',equal{jj});
        end
        
        fprintf('\n:::: EQUAL DETAILED OUTPUT ::::\n')
        for jj = 1:numel(equal)
            disp(['>>> ' equal{jj} ' <<<']);
            
            % Do not display the data field
            if ~strcmpi(equal{jj},'data')
                disp(n1.(equal{jj}));
                disp('----');               
            else disp(' Data fields are equal.');
                disp(' ----')
            end
        end
    end
    
    % Display results for non-equal fields
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
            else disp(' Data field is not equal. Generating difference image.');
                disp(' ----')
                showMontage(n1.data-n2.data);
                set(gcf,'Name','Nifti DATA Difference Image (nifti1.data - nifti2.data)');
            end
        end
    else
        disp('ALL FIELDS ARE EQUAL');
    end
end


%% RETURN THE RESULTS

results.allequal = isequal(n1,n2);
results.equal    = equal;
results.notequal = notequal; 
results.nonfield = nonfield;

if ~quiet
    fprintf('\nSUMMARY:\n\t%s fields were equal\n\t%s fields were not equal \n\t%s  fields were unique to one nifti\n\n',num2str(numel(equal)),num2str(numel(notequal)),num2str(numel(nonfield)));
end


return
