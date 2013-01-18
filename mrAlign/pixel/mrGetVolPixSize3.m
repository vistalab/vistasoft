function [volume_pix_size] = mrGetVolPixSize3(vAnatPath)
%function [volume_pix_size] = mrGetVolPixSize3(vAnatPath)
%
% PURPOSE: Prompt the user for the volume pixel size
% AUTHOR:  Poirson 
% DATE:    09.17.99
% HISTORY: Based on routine by Geoff Boynton 
% NOTES:   The default values [256/240,256/240,1/1] mean that
%          24 cm of brain image are interpolated on the 256 pixels
%          in the  x and y dimensions (units are pixels/mm).
%          And that the volume plane thickness is 1 pixel per 1 mm.
%

% See if we can just read the values

paramsFile = [vAnatPath filesep 'UnfoldParams'];

if ~exist([paramsFile '.mat'], 'file')
  disp ([paramsFile ' not found.']);
  disp ('Please enter values.');
  disp('Enter size of volume anatomy pixels/mm in x,y and z directions');
  volume_pix_size=input('Default is [256/240,256/240,1]: ');

  if isempty(volume_pix_size)
    volume_pix_size=[256/240,256/240,1];
  end

  %Create the file 'UnfoldParams.mat' in the subject's volume anatomy directory
  estr=(['save ' paramsFile ' volume_pix_size']);
  eval(estr);
else 	% Load in the infolding parameters (volme_pix_sizes)
  estr=(['load ' paramsFile]);
  eval(estr);
  volume_pix_size = volume_pix_size;
end

return




