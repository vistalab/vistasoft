function [xform, vectorTo] = niftiCreateXform(nii,xformType)
%Create a specified transform onto the supplied nifti struct. For
% data in slice format, we specify our output data xform according to
% certain rules. Our preferred orientation is PRS, but we do not want to
% change the slice dimension, so we apply these rules:
%
% 1. The slice dimension is third
% 2. The slice dimension does not change direction or axis
% 3. Except for the slice dimension, we remap any of LIA => RSP
% 4. If slice dimension is not L or R, then 2nd dimension is R
% 5. If slice dimension is not A or P, then 1st dimension is P
%
% For example,
% 
% xformIn = [...
%  'ASR' ; 'AIR' ; 'PSR' ; 'PIR' ; 'SAR' ; 'SPR' ; 'IAR' ; 'IPR' ;
%  'ASL' ; 'AIL' ; 'PSL' ; 'PIL' ; 'SAL' ; 'SPL' ; 'IAL' ; 'IPL' ;
%  'ARS' ; 'ALS' ; 'PRS' ; 'PLS' ; 'RAS' ; 'RPS' ; 'LAS' ; 'LPS' ;
%  'ARI' ; 'ALI' ; 'PRI' ; 'PLI' ; 'RAI' ; 'RPI' ; 'LAI' ; 'LPI' ;
%  'SRA' ; 'SLA' ; 'IRA' ; 'ILA' ; 'RSA' ; 'RIA' ; 'LSA' ; 'LIA' ;
%  'SRP' ; 'SLP' ; 'IRP' ; 'ILP' ; 'RSP' ; 'RIP' ; 'LSP' ; 'LIP' ;
%  ];
% 
% xformOut = xformIn;
% for ii = 1:length(xformIn)
%  xformOut(ii,:) = niftiCreateStringInplane(xformIn(ii,:),3);
%  fprintf('%s=>%s\n',xformIn(ii,:), xformOut(ii,:));
% end

% See niftiCreateStringInplane for the computation.
%
% USAGE
%  nii = readNifti(niftiFullPath);
%  xformType = 'Inplane';
%  niftiCreateXform(nii,xformType);
%
% INPUTS
%  Nifti struct
%  String specifying the transform to apply
%
% RETURNS
%  Xform matrix in the form a quaternion
%  vectorTo: string indicating the orientation that will result from
%            applying the outut xform to the input nifti
% See also niftiCreateStringInplane
%
% Copyright Stanford VistaLab 2013

xformType = mrvParamFormat(xformType);

xform = zeros(4); %Initialization
vectorTo = '';    %Initialization

sliceDim = niftiGet(nii,'slicedim');
if (sliceDim == 0) %Default to a slice dim of 3 if not populated
    sliceDim = 3;
end %if

switch xformType
    case 'inplane'
        vectorFrom = niftiCurrentOrientation(nii);
        vectorTo   = niftiCreateStringInplane(vectorFrom,sliceDim);
        xform      = niftiCreateXformBetweenStrings(vectorFrom,vectorTo);

        % check which dimensions have flips (rows with a -1), and then set
        % the 4th column appropriately
        isflipped = sum(xform(1:3,1:3),2) < 0;     
        dim = niftiGet(nii, 'dim');
        xform(isflipped,4) = dim(isflipped) + 1;   % set the 4th column of flipped rows to dim+1
        xform(~isflipped,4) = 0;                   % Set the 4th column of nonflipped rows to 0
                
    otherwise
        warning('vista:niftiError','The supplied transform type was unrecognized. Please try again. Returning empty transform.');
        return
end %switch

return
