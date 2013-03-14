function val = niftiGet(ni,param,varargin)
% Get data from various nifti data structures
%

if notDefined('ni'), error('Nifti data structure variable required'); end
if notDefined('param'), error('Parameter field required.'); end

param = mrvParamFormat(param);

%TODO: Add a nifti paramaterMapField

val = [];

switch param
    case 'data'
        if isfield(ni, 'data')
            val = ni.data; 
        else
            warning('vista:niftiError', 'No data information found in nifti. Returning empty');
            val = [];
        end
    case 'dim'
        if isfield(ni, 'dim')
            val = ni.dim; 
        else
            warning('vista:niftiError', 'No dimension information found in nifti. Returning empty');
            val = [];
        end
    case 'freqdim'
        if isfield(ni, 'freq_dim')
            val = ni.freq_dim; 
        else
            warning('vista:niftiError', 'No frequency dimension information found in nifti. Returning empty');
            val = [];
        end 
    case 'numslices'
        if isfield(ni, 'slice_end') && isfield(ni,'slice_start')
            val = ni.slice_end - ni.slice_start + 1; 
        else
            warning('vista:niftiError', 'No number of slices defined information found in nifti. Returning empty');
            val = [];
        end
    case 'phasedim'
        if isfield(ni, 'phase_dim')
            val = ni.phase_dim; 
        else
            warning('vista:niftiError', 'No phase dimension information found in nifti. Returning empty');
            val = [];
        end
    case 'pixdim'
        if isfield(ni, 'pixdim'), val = ni.pixdim;  
        else
            warning('vista:niftiError', 'No pixdim information found in nifti. Returning empty');
            val = [];
        end
	case 'qto_ijk'
        if isfield(ni, 'qto_ijk'), val = ni.qto_ijk;  
        else
            warning('vista:niftiError', 'No qto_ijk information found in nifti. Returning empty');
            val = [];
        end
 	case 'qto_xyz'
        if isfield(ni, 'qto_xyz'), val = ni.qto_xyz;  
        else
            warning('vista:niftiError', 'No qto_xyz information found in nifti. Returning empty');
            val = [];
        end   
    case 'slicedim'
        %Get the slice dimension field
        if isfield(ni, 'slice_dim')
            val = ni.slice_dim;
        else
            warning('vista:niftiError', 'No slicedims information found in nifti. Returning empty');
            val = [];
        end
        
        if val == 0, val = 3; end
    
    case 'slicedims'
        %Get the slice dimensions (i.e. the dimensions of each 2-D matrix
        %making up a slice)
        totDim = niftiGet(ni,'dim');
        val = totDim(setdiff(1:length(totDim),niftiGet(ni,'slice dim')));
        %val(1) = totDim(niftiGet(ni,'freq Dim'));
        %val(2) = totDim(niftiGet(ni,'phase Dim'));
 	case 'sto_ijk'
        if isfield(ni, 'qto_xyz'), val = ni.qto_xyz;  
        else
            warning('vista:niftiError', 'No qto_xyz information found in nifti. Returning empty');
            val = [];
        end   
 	case 'sto_xyz'
        if isfield(ni, 'qto_xyz'), val = ni.qto_xyz;  
        else
            warning('vista:niftiError', 'No qto_xyz information found in nifti. Returning empty');
            val = [];
        end   

    case 'voxelsize'
        if isfield(ni, 'voxelSize')
            val = ni.voxelSize; 
        else
            %Now we need to calculate voxelSize
            val = prod(niftiGet(ni,'Pixdim'));
        end
    otherwise
        warning('vista:nifti:niftiSet', 'Unknown parameter %s\n',param);
        
end %switch



return
