function dt = niftiClass2DataType(matlabType)
% Transform the string matlabType into a numerical codes used by NIFTI-1
%
%  dt = niftiClass2DataType(matlabType)
%
% Here is the table showing the assocation between Matlab type and NIFTI-1
% data type.
%
%  String (Matlab) ----> NIFTI-1
% -------------------------------
%            uint8 ----> 2
%            int16 ----> 4
%            int32 ----> 8
%  single, float32 ----> 16
%        complex64 ----> 32
%  double, float64 ----> 64
%            RGB24 ----> 128
%             int8 ----> 256
%           unit16 ----> 512
%           uint32 ----> 768
%       complex128 ----> 1792
%
% Franco (c) Stanford Vista team, 2012

matlabType = mrvParamFormat(matlabType);
switch matlabType
    case {'uint8'},      dt = 2;
    case {'int16'},      dt = 4;
    case {'int32'},      dt = 8;
    case {'float32','single'}, dt = 16;
    case {'complex64'},  dt = 32';
    case {'float64','double'}, dt = 64;
    case {'rgb64'},      dt = 128;
    case {'int8'},       dt = 256;
    case {'uint16'},     dt = 512;
    case {'uint32'},     dt = 768;
    case {'complex128'}, dt = 1792;
    otherwise,
        error('Unknown string %s\n',matlabType);
        
end

end