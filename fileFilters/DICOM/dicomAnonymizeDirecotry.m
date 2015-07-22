function dicomAnonymizeDirecotry(dcm_in_dir, dcm_out_dir, dcm_out_base, fields_kept, keep_private)
%
% dicomAnonymizeDirecotry([dcm_in_dir], [dcm_out_dir], [dcm_out_base], [fields_kept], [keep_private])
%
% Anonymize a directory of dicom files. This will remove medical/private
% fields while keeping some (see 'fields_kept') untouched. Uses
% 'dicomanon.m' to do the actual work. By default, if no 'dcm_out_base' or
% 'dcm_out_dir' is provided, this will overwrite existing dicom files with
% new, anonymized files with the same name. CAUTION: This can be slow if
% you're working with a large number of files (~30sec for 200 dicoms)
% 
% INPUTS:
%   dcm_in_dir      Directory containing dicom files
%                   DEFAULT=current working directory
% 
%   dcm_out_dir     Directory to place new, anonymized files
%                   DEFAULT=dcm_dir_in
% 
%   dcm_out_base    Name to append to original dicom file name
%                   DEFAULT=None
% 
%   fields_kept     String array containing fields to keep untouched
%                   DEFAULT= {'PatientSex', 'PatientAge', 'PatientWeight',
%                       'StudyInstanceUID','SeriesInstanceUID','StudyID'};
%   keep_private    [Boolean] Keep all "Private" fields in the dicom. This
%                   can be important for reconstruction.
%                   DEFAULT=True
% 
%   FIELDS REMOVED  SEE EOF.
% 
% EXAMPLE USAGE
%   dicomAnonymizeDirecotry(pwd, '~/Desktop/anonymizedDicoms', 'anon', {'PatientSex'})
%
% 
% SEE ALSO:
%   dicomanon.m
% 
% (C) Stanford VISTA, 2015
% 
% 

%% Check for dicom toolbox
f = which('dicomanon');
if isempty(f) || ~exist(f, 'file')
    error('DICOM image processing toolbox not found on path');
end


%% Set the default fields to be kept

default_keep_fields = {'PatientSex', 'PatientAge', 'PatientWeight',...
                       'StudyInstanceUID','SeriesInstanceUID','StudyID'};


%% Parse inputs and set defaults

% Set the default out-base
if ~exist('dcmd_in', 'var') || isempty(dcm_in_dir)
    dcm_in_dir = pwd;
end

% Set the default out-base. If  none is provided then the overwrite flag
% will be set and we'll anonymize in place.
if ~exist('dcm_out_base', 'var') || isempty(dcm_out_base)
    overwrite = true;
else
    overwrite = false;
end

% Set the default fields to keep if none were passed in.
if ~exist('fields_kept', 'var') || isempty(fields_kept)
    fields_kept = default_keep_fields;
end

% If there was no output directory passed in, then write them out where
% they live now. 
if ~exist('dcm_out_dir', 'var') || isempty(dcm_out_dir)
    dcm_out_dir = dcm_in_dir;
end

% If the user did not specify to keep the private fields we opt to keep
% them by default.
if ~exist('keep_private', 'var') || isempty(keep_private)
    keep_private = true;
end

%% DICOM file i/o

% Get a struct array of all the files in the directory
if isdir(dcm_in_dir)
    dicoms = dir(dcm_in_dir);
else
    error('Not a directory');
end

if ~exist(dcm_out_dir, 'dir')
    mkdir(dcm_out_dir)
end


%% Anonymize

fprintf('Anonymizing %d dicom files...\n', numel(dicoms)); 
tic;

% Initialize the progress of the parfor loop
parfor_progress(numel(dicoms));

parfor ii = 1:numel(dicoms) 
    parfor_progress;
    
    % Make sure this file is actually a file and not empty.
    if dicoms(ii).isdir ~= 1 && dicoms(ii).bytes > 0
        try
            if overwrite
                out_name = fullfile(dcm_out_dir, dicoms(ii).name);
            else
                out_name = fullfile(dcm_out_dir, [dicoms(ii).name '_' dcm_out_base]);
            end
            dicomanon(fullfile(dcm_in_dir, dicoms(ii).name), out_name, ... 
                      'keep', fields_kept, 'WritePrivate', keep_private);
        catch
        end
    else
    end
end

toc
disp('Done!');


return


%% FIELDS REMOVED 

% FROM ftp://medical.nema.org/medical/dicom/final/sup55_ft.pdf

% 
% Instance Creator UID (0008,0014)
% SOP Instance UID (0008,0018)
% Accession Number (0008,0050)
% Institution Name (0008,0080)
% Institution Address (0008,0081)
% Referring Physician?s Name (0008,0090)
% Referring Physician?s Address (0008,0092)
% Referring Physician?s Telephone Numbers (0008,0094)
% Station Name (0008,1010)
% Study Description (0008,1030)
% Series Description (0008,103E)
% Institutional Department Name (0008,1040)
% Physician(s) of Record (0008,1048)
% Performing Physicians? Name (0008,1050)
% Name of Physician(s) Reading Study (0008,1060)
% Operators? Name (0008,1070)
% Admitting Diagnoses Description (0008,1080)
% Referenced SOP Instance UID (0008,1155)
% Derivation Description (0008,2111)
% Patient?s Name (0010,0010)
% Patient ID (0010,0020)
% Patient?s Birth Date (0010,0030)
% Patient?s Birth Time (0010,0032)
% Patient?s Sex (0010,0040)
% Other Patient Ids (0010,1000)
% Other Patient Names (0010,1001)
% Patient?s Age (0010,1010)
% Patient?s Size (0010,1020)
% Patient?s Weight (0010,1030)
% Medical Record Locator (0010,1090)
% Ethnic Group (0010,2160)
% Occupation (0010,2180)
% Additional Patient?s History (0010,21B0)
% Patient Comments (0010,4000)
% Device Serial Number (0018,1000)
% Protocol Name (0018,1030)
% Study Instance UID (0020,000D)
% Series Instance UID (0020,000E)
% Study ID (0020,0010)
% Frame of Reference UID (0020,0052)
% Synchronization Frame of Reference UID (0020,0200)
% Image Comments (0020,4000)
% Request Attributes Sequence (0040,0275)
% UID (0040,A124)
% Content Sequence (0040,A730)
% Storage Media File-set UID (0088,0140)
% Referenced Frame of Reference UID (3006,0024)
% Related Frame of Reference UID (3006,00C2)
% 
% 