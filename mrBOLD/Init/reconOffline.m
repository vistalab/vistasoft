function reconOffline(pfileDir,writeEfileFlag,bigEndian,seqType);
% reconOffline([pfileDir,writeEfileFlag,bigEndian,seqType]);
%
% (For linux and Mac OSX only):
% Use gary's recon code (in /biac2/kgs/dataTools/) to
% make Pmags and E-file headers from Pfiles without
% logging into lucas.
%
% pfileDir: where to find the Pfiles. Defaults to the
% current directory, and also checks if there's a Raw/Pfiles
% directory relative to that directory. So you can run this
% straight from the session directory.
%
% writeEfileFlag: if 0, won't re-write the E-file headers. By
% default, it does (1).
%
% bigEndian: flag on whether the Pfiles are big-endian or
% little-endian format. Short answer: if the data were collected
% (at stanford lucas center) prior to late February 2005, set
% this flag to 1; otherwise, ignore it (it defaults to 0).
% 
% seqType: flag for sequence type, when the sequence has special needs.
% defaults to 0 (standard sequence), 1 = 3D sequence (needs to run 3dcode),
% other values currently ignored...
%
% This uses grecons.lnx and the -O (one file) and -b (byte swap, *Endian dependent)
% flags -- otherwise the Pmags come out messy.
%
% 09/04 ras.
% 03/05 ras: updated to deal w/ little-endian files, after
% the 3T at Lucas switched to the Excite system.
% 01/07 dar: included seqType flag, updated call to target
% "grecons.lnx" (not "grecons")
% 10/10 kw/al: updated to version 95 of grecon(grecon15) and writeihdr 
% To do:
% +could use a good way to auto-detect if 3dcode should be run.

if ~isunix
    fprintf('Sorry, unix systems only (linux and Mac OS X).\n');
    return
end

if ~exist('pfileDir','var') | isempty(pfileDir)
    pfileDir = pwd;
end

if ~exist('writeEfileFlag','var') | isempty(writeEfileFlag)
    writeEfileFlag = 1;
end

if ~exist('bigEndian','var') | isempty(bigEndian)
    bigEndian = 0;
end

if ~exist('seqType','var') | isempty(seqType)
    seqType = 0;
end


pattern = fullfile(pfileDir,'P*.7');
w = dir(pattern);

% may not be pfiles in the current directory, but
% in Raw/Pfiles. Check this as a backup:
if isempty(w)
    pfileDir = fullfile(pfileDir,'Raw','Pfiles');
    pattern = fullfile(pfileDir,'P*.7');
    w = dir(pattern);
end

% if still no pfiles, you're outta luck
if isempty(w)
    error(sprintf('No Pfiles found in %s.',pfileDir));
end

callingDir = pwd;
cd(pfileDir);

bfilepattern = fullfile(pfileDir,'B0*'); %check for preexisting B0* files.  If present, will not delete later
b = dir(bfilepattern);

for i = 1:length(w)
    fname = w(i).name;

    if writeEfileFlag==1
        cmd = sprintf('/biac2/kgs/dataTools/writeihdr15 %s',fname);
        unix(cmd);
        fprintf('Wrote E-file header for %s.\n',fname);
    end

    if seqType == 1
        %this block MUST come before recon call...creates files to be used for
        %3d recon - Original 'P*****.7' is converted to '3d_P*****.7' which becomes
        %the active file
        cmd = sprintf('/biac2/kgs/dataTools/3dcode %s 3d_%s',fname,fname); 
        unix(cmd);
        fprintf('3dcode has converted %s to 3d_%s - ready for recon\n',fname,fname);
        oldfname = fname;
        fname = sprintf('3d_%s',fname);
    end

    if bigEndian
        % big endian: for scans before the upgrade in Feb 2005
        cmd = sprintf('/biac2/kgs/dataTools/grecons.lnx -O -b %s',fname);
    else
        % little endian: after the upgrade, Pfiles now don't
        % need to be byte-swapped
        cmd = sprintf('/biac2/kgs/dataTools/grecons15.lnx -O %s',fname);
    end
    unix(cmd);
    
    if seqType == 1
        cmd = sprintf('mv %s.mag %s.mag', fname, oldfname);
        unix(cmd);
        fprintf('\n\n\t*****Reconned %s to %s.mag*****\n\n',fname,oldfname);
        fname = oldfname;
    else
        fprintf('\n\n\t*****Reconned %s*****\n\n',fname);
    end
    
    if isempty(b)
        % move the B0 estimate files into their own subdirectory,
        % and rename the B0.* files to I.*, so code like loadVolume
        % which looks for the pattern I* can find them. (ras, 02/06)
        % modified to create subdirectory for each scan (dar 01/07)
        try
            if ~isempty(dir('B0.*'))
                dirname = sprintf('B0_%s',fname(1:6));
                cmd = sprintf('mkdir %s',dirname);
                unix(cmd)
                nfiles = length(dir('B0.*'));
                for i = 1:nfiles
                    src = sprintf('B0.%03.0f', i);
                    tgt = sprintf('%s/I.%03.0f',dirname, i);
                    movefile(src, tgt);
                end
            end
        end
    end
end
if ~isempty(dir('B0_*'))
    mkdir B0
    cmd = sprintf('mv B0_*/ B0/')
    unix(cmd)
end
cd(callingDir);
return