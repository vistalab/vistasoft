function val = niftiGet(ni,param,varargin)
%
% Get a value from a nifti structure
%
%   val = niftiGet(nii,param,varargin)
%
% USAGE
%  val = niftiGet(nii,'Data');
%
% INPUTS
%  Nifti struct - The structure read in by niftiRead
%  param - String parameter specifying the value to retrieve
%
% RETURNS
%  Value (or values) stored in the nifti or calculated from values stored
%  in the nifti


if notDefined('ni'), error('Nifti data structure variable required'); end
if notDefined('param'), error('Parameter field required.'); end

param = mrvParamFormat(param);

%TODO: Add a nifti paramaterMapField

val = [];

switch param
    case 'calmax'
        if isfield(ni, 'cal_max')
            val = ni.cal_max;
        else
            warning('vista:niftiError', 'No maximum value information found in nifti. Returning empty');
            val = [];
        end
        
    case 'calmin'
        if isfield(ni, 'cal_min')
            val = ni.cal_min;
        else
            warning('vista:niftiError', 'No minimum value information found in nifti. Returning empty');
            val = [];
        end
        
    case 'data'
        if isfield(ni, 'data')
            val = ni.data;
        else
            warning('vista:niftiError', 'No data information found in nifti. Returning empty');
            val = [];
        end
        
    case 'datatype'
        if isfield(ni, 'data')
            val = niftiClass2DataType(class(ni.data));
        else            
            warning('vista:niftiError', 'No data information found in nifti. Returning empty');
            val = [];
        end
        
    case 'dim'
        if isfield(ni, 'dim')
            val = ni.dim;
            
            if length(val) < 3, val = [val 1]; end
            
        else
            warning('vista:niftiError', 'No dimension information found in nifti. Returning empty');
            val = [];
        end        
        
    case 'fname'
        if isfield(ni, 'fname')
            val = ni.fname;
        else
            warning('vista:niftiError', 'No file name information found in nifti. Returning empty');
            val = [];
        end
        
    case 'freqdim'
        if isfield(ni, 'freq_dim')
            val = ni.freq_dim;
        else
            warning('vista:niftiError', 'No frequency dimension information found in nifti. Returning empty');
            val = [];
        end
        
    case 'ndim'
        if isfield(ni, 'ndim')
            val = ni.ndim;
        else
            warning('vista:niftiError', 'No number of dimensions information found in nifti. Returning empty');
            val = [];
        end

    case 'numslices'
        if isfield(ni, 'slice_end') && isfield(ni,'slice_start')
            val = ni.slice_end - ni.slice_start + 1;
        else
            error('vista:niftiError', 'No number of slices defined information found in nifti. Returning empty');
        end
        if ni.slice_end == 0 || ni.slice_start == 0
            %First, let's try to use slicedim on the 'dim' field
            dims = niftiGet(ni,'Dim');
            sliceDim = niftiGet(ni,'Slice Dim');
            val = dims(sliceDim);
        end    
        
        if val == 0
            error('vista:niftiError', 'The number of slices are not properly defined in this nifti. Please ensure that slice_start and slice_end are non-zero.');
        end

    case 'phasedim'
        if isfield(ni, 'phase_dim')
            val = ni.phase_dim;
        else
            warning('vista:niftiError', 'No phase dimension information found in nifti. Returning empty');
            val = [];
        end
        
    case 'pixdim'
        % niftiGet(ni, 'pixdim', varargin);
        % varargin in pairs, including:
        %   'xyz_units', xyz_units
        %   'time_units', time_units
        % Example:
        % niftiGet(ni, 'pixdim');
        % niftiGet(ni, 'pixdim', 'xyz_units', 'mm', 'time_units', 's');
        if isfield(ni, 'pixdim')
            val = ni.pixdim; 
            if length(val) < 3, val = [val val(end)]; end 
            
            % Check for units
            if ~isempty(varargin)
                for ii = 1:2:length(varargin)
                   switch varargin{ii}
                       case 'xyz_units' 
                           oldUnitStr = ni.xyz_units;
                           newUnitStr = varargin{ii+1};
                           val(1:3) = unitConvert(val(1:3),'length',oldUnitStr,newUnitStr);
                       case 'time_units'
                           oldUnitStr = ni.time_units;
                           newUnitStr = varargin{ii+1};
                           val(4) = unitConvert(val(4),'time',oldUnitStr,newUnitStr);                           
                   end
                end
            end
        else
            warning('vista:niftiError', 'No pixdim information found in nifti. Returning empty');
            val = [];
        end
        
    case 'qform_code'
        if isfield(ni, 'qform_code'), val = ni.qform_code;
        else
            warning('vista:niftiError', 'No qform_code information found in nifti. Returning empty');
            val = [];
        end
        
    case 'sform_code'
        if isfield(ni, 'sform_code'), val = ni.sform_code;
        else
            warning('vista:niftiError', 'No sform_code information found in nifti. Returning empty');
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
        %Default to a slice dim of '3'
        if val == 0, val = 3; end
        
    case 'slicedims'
        %Get the slice dimensions (i.e. the dimensions of each 2-D matrix
        %making up a slice)
        val = niftiGet(ni,'dim');
        sliceDimLogical = true(size(val));
        sliceDimLogical(niftiGet(ni,'phase dim')) = 0;
        sliceDimLogical(niftiGet(ni,'freq dim')) = 0;
        val(sliceDimLogical) = [];
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
        
    case {'params','scanparams','descrip','description'}
        if isfield(ni,'descrip') 
            val = niftiGetParamsFromDescrip(ni);
        else
            warning('vista:niftiError','Descrip field does not exist');
            val = [];
        end
            
        
    otherwise
         error('Unknown parameter %s\n',param);       
        
end %switch



return
