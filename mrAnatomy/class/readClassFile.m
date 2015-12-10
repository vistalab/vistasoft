function [class,mmPerVox,ni] = readClassFile(filename,headerOnlyFlag,voiOnlyFlag,hemisphere)
%
%  [class,mmPerVox,niftiStruct] = readClassFile(filename,[headerOnlyFlag=false],[voiOnlyFlag=true],[hemisphere='']);
%
% AUTHOR:  Wandell
% DATE: 06.24.96
% PURPOSE:
%   Read the classification file produced by mrGray or the new ITKGray (NIFTI format).
%   The results are returned in a structure.
%
%   The 'hemisphere' argument is ONLY used when loading a new ITKGray NIFTI
%   class file. We need it for that since both hemispheres are stored in
%   one file. For old mrGray class files, 'hemisphere' is ignored.
%
% Examples:
%    Read in all the data, not just the part in the VOI
%    class = readClassFile('rightWhole.class',0,0);
%
%    Read in just the header.
%    class = readClassFile('rightWhole.class',1);
%
% MODIFICATIONS:
% 07.20.98 SJC	commented out figures
% 09.02.98 SJC	Added the optional input argument 'headerOnlyFlag'
%		which, if set to 1, makes the function only read
%		and return the header information instead of
%		reading in the entire class file.
% 04.13.99 SJC Added the optional input argument 'voiOnlyFlag'
%		which, if set to 1, crops the classification data to the
%		volume of interest only, and if set to 0 does not crop it.
% 06.18.99 SJC Changed the pause after the message window pops up to 'drawnow'
% 09.15.99 BW/WP
%               The VOI now returns in Matlab coordinates (1:N),
%               rather than C coordinates (0:(n-1)).  This is now
%               consistent with the update in readGrayGraph.
% 2002.11.01 RFD- added '=>uchar' to force fread to return a uchar array.
% Also removed the GUI msgbox.
% 2003.09.23 RFD: added 3rd option for voiOnlyFlag to allow the full
% (unclipped) data to be returned AND preserves the VOI clipping values in
% the header. Note that the stuct returned by this mode may be incompatible
% with writeCLassFIle. However, it is useful for callers who want to do
% their own clipping.
% 2006.08.21 Ress: fixed bug associated with use fscanf function in Matlab
% version 7.2. Substituted use of "line = fgetl(fp)" instead of similar
% fscanf syntax.
% 2007.12.21 RFD: added code to load new ITKGray NIFTI files.

if(notDefined('filename'))
    opts = {'*.nii;*.nii.gz', 'NIFTI files (*.nii,*.nii.gz)'; '*.*','All Files (*.*)'};
    [f, p]=uigetfile(opts, 'Pick a class file');
    if(isequal(f,0)|| isequal(p,0)), disp('user canceled.'); return; end
    if(isempty(p)), p = pwd; end
    filename = fullFile(p,f);
end

if(isstruct(filename)), class.filename = filename.fname;
else                    class.filename = filename; end

% Set up values for different data types
class.type.unknown = (0*16);
class.type.white   = (1*16);
class.type.gray    = (2*16);
class.type.csf     = (3*16);
class.type.other   = (4*16);


% Parse nifti file
labels = mrGrayGetLabels;
if ~exist('hemisphere','var')
    if(strfind(lower(class.filename),'_left'))
        hemisphere = 'left';
    elseif(strfind(lower(class.filename),'_right'))
        hemisphere = 'right';
    else
        error('Hemisphere must be specified as an input argument or in the filename.');
    end
    if(~isstruct(filename))
        % We'll also allow the '_left' and '_right' files to not actually exist:
        if(~exist(filename,'file'))
            if(strfind(lower(filename),'_left'))
                ind = strfind(lower(filename),'_left');
                hemisphere = 'left';
                filename = filename([1:ind-1,ind+5:end]);
            elseif(strfind(lower(filename),'_right'))
                ind = strfind(lower(filename),'_right');
                hemisphere = 'right';
                filename = filename([1:ind-1,ind+6:end]);
            else
                error('file not found.');
            end
        end
    end
end

if ~isstruct(filename), ni = niftiRead(filename); else ni = filename; end

class.header.version = 2;
class.header.minor = 0;

% 	%The following is the old way, which didn't call
% 	%niftiApplyCannonicalXform
%
%     % Flip voxel order to conform the vAnatomy spec
%     % NOTE: this assumes that the nifti data are in the cannonical axial
%     % orientation. If they might not be, call niftiAppyCannonicalXform.
%     % The cannonical NFTI dim order is [X Y Z], but class file format is
%     % [Y Z X], so we permute. (Note that vAnatomy is [Z Y X]. Go figure.
%     % We also need to flip Z and Y.
%     %tmp = flipdim(flipdim(permute(uint8(ni.data),[2 3 1]),1),2);
% 	%tmp = permute(uint8(ni.data),[2 3 1]);

%Need to unify the handling of class files with the new handling of
%of volume anatomy. This code should handle class nifti's the same way
%volume anatomy nifti's are handled.
%BUT!! with the added fun of going from [X Y Z] to [Y X Z]
% Because latter in the code calls to the gray nodes (3xn matrix)
% permute indices, assuming [y x z] addressing.
% I would think at some point this should get sorted.
% JMA
ni = niftiApplyCannonicalXform(ni);
%mrAnatRotatAnalyze does a permute [ 3 2 1], then a flipdim(data,2),
%flipdim(data,1)
tmp = mrAnatRotateAnalyze(uint8(ni.data));

tmp = permute(uint8(tmp),[2 1 3]);
%So now, w.r.t. the nifti we are [-2 -3 1]
%probably should have better code to keep track of this.

class.data = zeros(size(tmp),'uint8')+class.type.unknown;
class.data(tmp==labels.CSF) = class.type.csf;


if(lower(hemisphere(1))=='r' || hemisphere(1)==1)
    class.data(tmp==labels.rightWhite) = class.type.white;
    class.data(tmp==labels.rightGray) = class.type.gray;
    class.data(tmp==labels.leftGray)  = class.type.csf;
elseif(lower(hemisphere(1))=='l' || hemisphere(1)==0)
    class.data(tmp==labels.leftWhite) = class.type.white;
    class.data(tmp==labels.leftGray) = class.type.gray;
    class.data(tmp==labels.rightGray)  = class.type.csf;
else
    error('Unknown hemisphere label');
end
% Include other stuff
allLabels = struct2cell(labels); allLabels = [allLabels{:}];
otherLabels = tmp>max(allLabels);
class.data(otherLabels) = tmp(otherLabels)-min(tmp(otherLabels(:))) + class.type.other;

class.header.xsize = ni.dim(2);
class.header.ysize = ni.dim(3);
class.header.zsize = ni.dim(1);

class.header.voi = [1 class.header.xsize 1 class.header.ysize 1 class.header.zsize];
class.header.params = 'ITKGray';
class.header.mmPerVox = ni.pixdim([2 3 1]);
%This qto_xyz is INCORRECT it correpsonds to the canonically oriented
%nifti, before the permute flip contortions.
%I'm not sure what this field gets used for, so I'm not changing it yet
%It seems kinda dangerous to me though.
%JMA
class.header.qto_xyz = ni.qto_xyz;
mmPerVox = ni.pixdim([2,3,1]);



return;


