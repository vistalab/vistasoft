function [rows, cols, nFrames] = convertPmagToBshort(PmagDir,bShortDir,mrSESSION,littleEndian)

% [rows, cols, nFrames] = convertPmagToBshort(PmagDir,bShortDir,mrSESSION)
% This function convertPmagToBshort converts Pmag format to bshort format
% The bshort formats are stored in the .bshort and .hdr files in the specified 
% directory. This code is based on LoadRecon.m and GetRecon.m files in 
% mrLoadRet version 3.0
%
% INPUTS
%      PmagDir      : Directory name containing the Pmag files
%      bShortDir    : Directory name where the bShort files are going to be stored 
%      mrSESSION    : mrSESSION structure (not the file)
% OUTPUTS
%      rows         : Number of rows in a single frame
%      cols         : Number of columns in a single frame
%      nFrames      : Number of Frames
% ------------------------------------------------------------------ 
% Prateek 03/29/2002
%
% History:
% -------
%  Jul 23, 2002 : Changed to work with mrSESSION structure and
%  integrated with convertRaw2Bsh.m file (PB)
%  Nov 23, 2004 : Added ability to work with zippped Pmags (RS)
%-----------------------------------------------------------------------------
if ieNotDefined('PmagDir')
    PmagDir = fullfile(pwd,'Raw','Pfiles');
end

if ieNotDefined('bShortDir')
    bShortDir = fullfile(pwd,'mcTempFiles');
end

if ieNotDefined('littleEndian')
    littleEndian = 1;
end

if ieNotDefined('mrSESSION')
    load mrSESSION;
end

if ~isdir(PmagDir)      
  error('Pmag Directory not Found .. Please check it again .....!!!');
end

% figure out if we want to read/write big or little-endian
if littleEndian==1
    endianFlag = 'ieee-le';
else
    endianFlag = 'ieee-be';
end

%------------------------------------------------------
% there may be w/ zipped Pmags in PmagDir -- unzip
%------------------------------------------------------
zipFlag = 0; 
zipFiles = fullfile(PmagDir,'*.bz2');     
zNameDir = dir(zipFiles);
unsorted_zNames = {zNameDir.name};
zNames = sort(unsorted_zNames);

if ~isempty(zNames)
    if isunix
        % decompress 'em
        msg = sprintf('Found %i zipped files. Attempting to decompress...\n',length(zNames));
        disp(msg);
        cmd = sprintf('gunzip2 %s/*.bz2',PmagDir);
        unix(cmd);
        zipFlag = 1;
    else
        % no current way to decompress -- warn
        msg = sprintf('Found %i zipped files, but not unix so can''t decompress.\n',length(zNames));
        warning(msg);
    end
end

% Find existing Pmags
Magfiles = fullfile(PmagDir,'*.mag');     
fNameDir = dir(Magfiles);
unsorted_fNames = {fNameDir.name};
fNames = sort(unsorted_fNames);
      
  

num_scans = length(fNames);

%------------------------------------------------------
% Create a seq.info file using the first scan parameters
% Note to check the ntrs and TR for every scan
% ------------------------------------------------------
createseqinfo(bShortDir,mrSESSION);


%-------------------------
% Conversion of Pmag files
% ------------------------
for iScan = 1:num_scans

    scanParams = mrSESSION.functionals(iScan);
    temp = scanParams.cropSize;
    rows = temp(1);
    cols = temp(2);

    nFrames = scanParams.totalFrames;
    fSize = scanParams.fullSize; 

    shifts = [0 0];                % Assumption(No Rotation)
    x0 = scanParams.crop(1, 1) + shifts(2);
    xN = scanParams.crop(2, 1) + shifts(2);
    y0 = scanParams.crop(1, 2) + shifts(1);
    yN = scanParams.crop(2, 2) + shifts(1);

    fileName = scanParams.PfileName;  
    fName = fullfile(PmagDir,fileName);

    %------------------------------------------------------
    % Added to display it while running . note there are no
    % semi-colons after the statement
    %-------------------------------------------------------
    
    Scan_Num     =  iScan
    PmagfileName = fileName
    
    if iScan < 10
       dirNum = strcat('00',num2str(iScan));
    elseif FileNum < 100
       dirNum = strcat('0',num2str(iScan));
    end

    %---------------
    % Scan Directory
    %---------------
    
    bShortDir1 = fullfile(bShortDir,dirNum);
    status = mkdir(bShortDir,dirNum);

    if status == 0
      error('Directory not created ');
    end

    for iSlice = 1:length(scanParams.slices)
   
       %--------------------------------
       % Offset based on the slice number
       %---------------------------------
       
       offset = prod(fSize)*2*(iSlice -1)*nFrames;

       mN = fopen(fName, 'r', endianFlag); % 'ieee-be'
       tSeries = zeros([nFrames, fSize]);
       fseek(mN, offset, 0); % Skip to desired slice
       for f=1:nFrames
         img = fread(mN, fSize, 'int16')';
         chk = size(img)==fSize;
         if (and(chk(1),chk(2)) == 1)
         tSeries(f, :, :) = img;
         end
       end
       fclose(mN);

       %-------------------------------
       % Removing the first few frames.
       %-------------------------------
       f0 = scanParams.junkFirstFrames+1;
       nFrames1 = scanParams.nFrames;
       fEnd = f0 + nFrames1 - 1;

       %-------------------------------------------------------------
       % Do crop in time/space and reshape to standard t-series shape: 
       %--------------------------------------------------------------
       tSeries = tSeries(f0:fEnd, :, :);
       tSeries = tSeries(:, y0:yN, x0:xN);
       nPixels = (yN-y0+1)*(xN-x0+1);
       tSeries = reshape(tSeries, nFrames1, nPixels);

       %---------------------------------------
       % Conversion of tSeries to bShort format.
       % --------------------------------------
       for i = 1:nFrames1
         tempmat = reshape(tSeries(i,:),rows,cols);  
         tSeries(i,:) = reshape(tempmat',1,rows*cols); 
       end
 
       vec = reshape(tSeries',1,nPixels*nFrames1);    
  
       % ------------------------
       % Getting bShort file Name
       % ------------------------
       FileNum = scanParams.slices(iSlice)-1 ;

       if FileNum < 10
          bShortFileNum = strcat('00',num2str(FileNum));
       elseif FileNum < 100
          bShortFileNum = strcat('0',num2str(FileNum));
       else
          bShortFileNum = num2str(FileNum);
       end

       bShortFileName = strcat('f_',bShortFileNum,'.bshort');
       HdrFileName    = strcat('f_',bShortFileNum,'.hdr');
       
       bShortName = fullfile(bShortDir1,bShortFileName)
       hdrName = fullfile(bShortDir1,HdrFileName); 

       % ----------------------------------------------------
       %fprintf('\n opening %s for writing....  \n',out_bsh);
       %-----------------------------------------------------
       [fid message]=fopen(bShortName,'w', 'ieee-be'); %endianFlag) % 'ieee-be'
       fwrite(fid,vec,'short');
       fclose(fid);

       %-------------------------------------------
       %fprintf('\n writing header %s \n',out_hdr);
       %--------------------------------------------
       [fid message]=fopen(hdrName,'w');
       fprintf(fid,'%d %d %d 0',rows,cols,nFrames1);
       fclose(fid);     

    end

end


%------------------------------------------------------
% If we unzipped stuff earlier, rezip 'em
%------------------------------------------------------
if zipFlag==1
    fprintf(sprintf('Rezipping files in %s...',PmagDir));
    for i = 1:length(zNames)
        cmd = sprintf('bzip2 %s\%s',PmagDir,zNames{i});
        unix(cmd);
        fprintf('.');
    end
    fprintf('All done.\n');
end

return
