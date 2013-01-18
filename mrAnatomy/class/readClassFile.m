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
    opts = {'*.class;*.Class;*.CLASS', 'Class files (*.class)'; '*.nii;*.nii.gz', 'NIFTI files (*.nii,*.nii.gz)'; '*.*','All Files (*.*)'};
    [f, p]=uigetfile(opts, 'Pick a mrGray class file');
    if(isequal(f,0)|| isequal(p,0)), disp('user canceled.'); return; end
    if(isempty(p)), p = pwd; end
    filename = fullFile(p,f);
end
if ~exist('voiOnlyFlag','var')
    disp('Only reading data from the VOI, not the full volume.')
    voiOnlyFlag = 1;
end
if ~exist('headerOnlyFlag','var')
    headerOnlyFlag = 0;
end
if(isstruct(filename))
  classType = 'n';
  class.filename = filename.fname;
else
  classType = mrGrayCheckClassType(filename);
  % Save the filename used to read the data
  %
  class.filename = filename;
end

% Set up values for different data types
%
class.type.unknown = (0*16);
class.type.white   = (1*16);
class.type.gray    = (2*16);
class.type.csf     = (3*16);
class.type.other   = (4*16);

if(classType=='c')
    % Parse old mrGray class file
    %
    fp = fopen(class.filename,'r');

    % Read header information
    %
    line = fgetl(fp);
    class.header.version = sscanf(line, 'version= %d\n',1);
    line = fgetl(fp);
    class.header.minor = sscanf(line, 'minor= %d\n',1);

    line = fgetl(fp);
    class.header.voi(1) = sscanf(line, 'voi_xmin=%d\n',1);
    line = fgetl(fp);
    class.header.voi(2) = sscanf(line, 'voi_xmax=%d\n',1);
    line = fgetl(fp);
    class.header.voi(3) = sscanf(line, 'voi_ymin=%d\n',1);
    line = fgetl(fp);
    class.header.voi(4) = sscanf(line, 'voi_ymax=%d\n',1);
    line = fgetl(fp);
    class.header.voi(5) = sscanf(line, 'voi_zmin=%d\n',1);
    line = fgetl(fp);
    class.header.voi(6) = sscanf(line, 'voi_zmax=%d\n',1);
    %  convert VOI from C-0 indexing to Matlab 1-indexing
    class.header.voi = class.header.voi + 1;
    
    line = fgetl(fp);
    class.header.xsize = sscanf(line, 'xsize=%d\n',1);
    line = fgetl(fp);
    class.header.ysize = sscanf(line, 'ysize=%d\n',1);
    line = fgetl(fp);
    class.header.zsize = sscanf(line, 'zsize=%d\n',1);

    % if the headerOnlyFlag is set to zero, read in the data
    %
    if ~headerOnlyFlag
        line = fgetl(fp);
        csf_mean = sscanf(line, 'csf_mean=%g\n',1);
        line = fgetl(fp);
        gray_mean = sscanf(line, 'gray_mean=%g\n',1);
        line = fgetl(fp);
        white_mean = sscanf(line, 'white_mean=%g\n',1);
        line = fgetl(fp);
        stdev = sscanf(line, 'stdev=%g\n',1);
        line = fgetl(fp);
        confidence = sscanf(line, 'confidence=%g\n',1);
        line = fgetl(fp);
        smoothness = sscanf(line, 'smoothness=%d\n',1);
        class.header.params = ...
            [ csf_mean gray_mean white_mean stdev confidence smoothness];

        % Read the entire raw data set
        % 2002.11.01 RFD- added '=>uchar' to force fread to return a uchar array.
        % This is **much** faster.
        [im, cnt ] = fread(fp,'uchar=>uchar');
        fclose(fp);

        % Reshape the volume
        %
        class.data = ...
            reshape(im,[class.header.xsize,class.header.ysize,class.header.zsize]);

        % figure(1);
        % imagesc(class.data(:,:,34)),axis image

        % If the voiOnlyFlag is set, extract that portion of the data,
        % shrinking the total size of the data
        %
        if voiOnlyFlag>0
            class.data = class.data( ...
                (class.header.voi(1):class.header.voi(2)), ...
                (class.header.voi(3):class.header.voi(4)), ...
                (class.header.voi(5):class.header.voi(6)));
        elseif voiOnlyFlag==0
            % If the voiOnlyFlag was not set, the data size may mis-match
            % the voi size.  So, we need to make sure the voi
            % for the returned class is the entire data set
            %
            disp('Setting class VOI to entire data set');
            class.header.voi(1) = 1; class.header.voi(2) = size(class.data,1);
            class.header.voi(3) = 1; class.header.voi(4) = size(class.data,2);
            class.header.voi(5) = 1; class.header.voi(6) = size(class.data,3);
        else
            disp('Data not clipped to VOI, but VOI header preserved.');
        end
    end
	mmPerVox = [];
	ni = [];
else
    % Parse new ITKGray file
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
	if(~isstruct(filename))
	  ni = readFileNifti(filename);
	else
	  ni = filename;
	end
    class.header.version = 2;
    class.header.minor = 0;
    % Flip voxel order to conform the vAnatomy spec
    % NOTE: this assumes that the nifti data are in the cannonical axial
    % orientation. If they might not be, call niftiAppyCannonicalXform.
    % The cannonical NFTI dim order is [X Y Z], but class file format is 
    % [Y Z X], so we permute. (Note that vAnatomy is [Z Y X]. Go figure.
    % We also need to flip Z and Y.
    tmp = flipdim(flipdim(permute(uint8(ni.data),[2 3 1]),1),2);
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
    class.header.mmPerVox = ni.pixdim(1:3);
    class.header.qto_xyz = ni.qto_xyz;
	mmPerVox = ni.pixdim([2,3,1]);
end

return;


