% regEstRot - Script to compute automatically the rotation and translation,
%             to be used as a callback.
%             It returns the rotation and translation in workspace variables
%             rot and trans.
%
%  Oscar Nestares - 5/99
%  ON - Added option to use the rotation and translation in bestrotvol
%       as initial alignment (useful to recompute automatically previous
%       manual alignments).
%   AB 4/21 - added NCoarseIter = [];  
NCoarseIter = [];
% extracting initial rotation and translation
if exist('Usebestrotvol')
  useFlag = Usebestrotvol
else
  useFlag = 0;
end
if ~useFlag
   % extract initial parameters from position of inplanes in the window
   regParamInit;
else
   % load initial parameters from bestrotvol.mat
   if exist('bestrotvol.mat')
      load bestrotvol
      Rinit = rot;
      Tinit = trans;
   else
      error('File bestrotvol.mat does not exist.')
   end
end

% registering
[rot, trans, Mf]=regVolInp(...
                 reshape(volume,[sagSize, numSlices]),... % volume
                 INPLANE.anat,...                         % inplanes
                 scaleFac,...  % inverse voxel size for inplanes and volume
                 Rinit,...     % initial rotation, from regParamInit
                 Tinit,...     % initial translation, from regParamInit
		 NCoarseIter,... % number of coarse iterations
                 'regEstFilIntGrad',... % function to estimate the intensity grad.
                  0);          % Plane by Plane flag = 0 (=>works globaly)

% done
msgbox('Automatic computation done');
