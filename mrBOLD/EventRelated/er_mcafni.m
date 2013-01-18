function er_mcafni(varargin);
% er_mcafni(varargin);
%
% Experimental code, an attemp to convert a unix script (mcafni) to matlab
% directly. If and when it works, it will allow use of the AFNI motion
% corrrection algorithm from within mrLoadRet. 
% 
% Notes
% 
% * removed any use of 'echoing' from the script -- have no idea if it's
% implementable in matlab
%
% Dependencies: getbinstem, bfile2afni, afni3dvolreg, afni2bvol
% Unix script ran off of: %~/bin/csh -f
% attempt to clean up: 3/10/03. Not working yet.
VERSION = 'Id: er_mcafni,v 1.1 2003/03/04 21:22:09 greve + ras Exp';

%%%% init
instem  = [];
outstem = [];
afnisession = ./mctmp
afniprefix = 
targstem = [];
targoff  = 0;  % target off
cleanup     = 1;
inplaneres  = [];  % in-plane resolution 
betplaneres = [];  % between-plane resolution (ie, slice thick)
TR          = [];

if(length(varargin) == 0) 
    usage_exit;
    qoe; return;
end

if any(findstr(varargin,'version'))
    fprintf('%s', VERSION)
    return;
end

s = parse_args(varargin);

instem = s.instem;
outsem = s.outstem;
targstem = s.targstem;
targoff = s.targoff;
afnisession = s.afnisession;
afniprefix = s.afniprefix;
inplaneres = s.inplaneres;
betplaneres = s.betplaneres;
TR = s.TR;
umaskarg = s.umaskarg;
umask = s.umask;
verbose = s.verbose;
echo = s.echo;
cleanup = s.cleanup;

%% Create the output directory %%
callingdir = pwd;
outdir  = fullfile(dirname,outstem);
outbase = fullfile(basename,outstem);
cd(dirname); mkdir(outdir); cd(callingdir);

[s,errs] = check_params;

%%%%%%% check that the AFNI commands exist %%%%%%%
% (rewrite for matlab)

%% Get dimensions of input %%
hdr0 = [instem '_000.hdr'];
fid0 = fopen(hdr0,'r');
nx     = fscanf(fid0,'%i');
ny     = fscanf(fid0,'%i');
nt     = fscanf(fid0,'%i');
endian = fscanf(fid0,'%i');
nz = `getnslices instem`;
fprintf( 'Input: Nrows %i, Ncols %i, Nslices %i, Ntp %i, Endian %i',ny,nx,nz,nt,endian)

inext = getbext instem`; % bshort or bfloat

%%% Convert input bfile to afni %%%
mkdir('afnisession')
afnistem = fullfile(afnisession,afniprefix);
convargs = {'-i',instem,'-o',afnistem};
convargs = [convargs {'-inplaneres',inplaneres,'-betplaneres',betplaneres}];
convargs = [convargs {'-TR',TR}];
fprintf( '---- Converting Input to AFNI ----------\n')
pwd
bfile2afni(convargs);
fprintf( '---------------------------------------\n')

%%% Convert target bfile to afni %%%
if ~isempty(targstem) 
    targprefix = ['targ-' afniprefix]);
    targafnistem = fullfile(afnisession,targprefix);
    convargs = {'-i',instem,'-o',targafnistem};
    convargs = [convargs {'-inplaneres',inplaneres,'-betplaneres',betplaneres}];
    convargs = [convargs {'-TR',TR}];
    fprintf( '---- Converting Input to AFNI ----------\n')
    pwd
    bfile2afni(convargs);
    fprintf( '---------------------------------------\n')
    
else
    targprefix = afniprefix;
end

fprintf('-------------- Motion Correcting ---------------------------\n');

% remove pre-existing files??? (ras)
if exist([afniprefix '.volreg+orig.BRIK'],'file')
    delete([afniprefix '.volreg+orig.BRIK'])
end
if exist([afniprefix '.volreg+orig.HEAD'],'file') 
    delete[afniprefix '.volreg+orig.HEAD'];
end

mcdat = fullfile(outdir,[outbase '.mcdat']); 
pwd
if (length(targstem) ~= 0) & ~isequal(targstem,instem) 
    status = afni3dvolreg('-verbose','-dfile',mcdat,...
        '-prefix',[afniprefix '.volreg'],...
        '-base',...
        ['targ-' afniprefix '+orig\ ' sprintf('%3d',targoff) '\ 'afniprefix+orig]);
    % probable error w/ the above line --- not sure how targoff fits into
    % the basename. -ras
    
    if(status) 
        error(['ERROR: afni3dvolreg existed with status %i',status]);
        qoe; return;
    end
else
    status = afni3dvolreg('-verbose','-dfile',mcdat,...
        '-prefix',[afniprefix.volreg],...
        '-base',[num2str(targoff) afniprefix '+orig']);
    % probable error w/ the above line --- not sure how targoff fits into
    % the basename. -ras
    
    if(status) 
        error(['ERROR: afni3dvolreg existed with status %i',status]);
        qoe; return;
    end
end
        
% add total displacment
tmpmc = /tmp/tmp_.mcdat
addmcparams mcdat > tmpmc
mv tmpmc mcdat
        
% convert back to b-files
afni2bvol -i afnisession/afniprefix.volreg+orig.BRIK \
-o outstem -oext inext
if(status) qoe; return;
            
%% Clean up the anfi files %%
if cleanup 
    delete([afnisession filesep afniprefix '+orig.*'])
    delete([afnisession filesep afniprefix '.volreg+orig.*'])
    delete([afnisession filesep targprefix '+orig.*']) 
    rmdir(afnisession)
end
                            
% if exist([instem '.bhdr'],'file') cp instem.bhdr outstem.bhdr end

fprintf( 'Those using the AFNI motion correction should cite: \n')
fprintf( '  RW Cox and A Jesmanowicz. \n')
fprintf( '  Real-time 3D image registration for functional MRI. \n')
fprintf( '  Magnetic Resonance in Medicine, 42: 1014-1018, 1999. \n')
fprintf( ' \n');
fprintf('mc-afni completed SUCCESSFULLY\n');

return;


%%%%%%%%%%%%--------------%%%%%%%%%%%%%%%%%%
function parse_args(args):
% parse the input arguments
while( length(varargin) ~= 0 )
    
    flag = args{1}; 
    args = args{2:end};
    
    switch(flag)
        
        case '-i',
            if ( length(varargin) == 0)  arg1err;   end
            s.instem = args{1}; args = args{2:end};
            break;
            
        case '-o',
            if ( length(varargin) == 0)  arg1err;   end
            s.outstem = args{1}; args = args{2:end};
            break;
            
        case '-t',
            if ( length(varargin) == 0)  arg1err;   end
            s.targstem = args{1}; args = args{2:end};
            break;
            
        case '-toff',
            if ( length(varargin) == 0)  arg1err;   end
            s.targoff = args{1}; args = args{2:end};
            break;
            
        case '-session',
            if ( length(varargin) == 0)  arg1err;   end
            s.afnisession = args{1}; args = args{2:end};
            break;
            
        case '-prefix',
            if ( length(varargin) == 0)  arg1err;   end
            s.afniprefix = args{1}; args = args{2:end};
            break;
            
        case {'-ipr','-inplaneres'},
            if ( length(varargin) == 0)  arg1err;   end
            s.inplaneres = args{1}; args = args{2:end};
            break;
            
        case {'-bpr','-betplaneres'},
            if ( length(varargin) == 0)  arg1err;   end
            s.betplaneres = args{1}; args = args{2:end};
            break;
            
        case '-TR'
            if ( length(varargin) == 0)  arg1err;   end
            s.TR = args{1}; args = args{2:end};
            break;
            
        case {'--version','-version'},
            fprintf('%s\n',VERSION)
            return;
            break;
            
        case '-umask',
            if ( length(varargin) == 0)  arg1err;   end
            s.umaskarg = '-umask args{1}';
            s.umask = args{1}; 
            args = args{2:end};
            break;
            
        case '-verbose',
            verbose ;
            break;
            
        case '-echo',
            s.echo = 1;
            break;
            
        case '-debug',
            s.verbose = 1;
            echo = 1;
            break;
            
        case '-nocleanup',
            s.cleanup = 0;
            break;
            
        otherwise,
            % don't worry about unrecognized flags
            args = args{2:end};
        
    end
end
    
    
return
%%%%%%%%%%%%--------------%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%--------------%%%%%%%%%%%%%%%%%%
function [s,errs] = check_params(s)

errs = 0;

if length(instem)==0 
    echo 'ERROR: no input stem specified'|& tee -a LF 
    qoe; return
end

i0 = instem'_000.hdr';
if exist(i0,'file') 
    error(['ERROR: cannot find ', i0])
end

if (length(targstem) ~= 0) 
    i0 = [targstem '_000.hdr'];
    if ~exist(i0) 
        error(['ERROR: cannot find ', i0])
        qoe; return;
    end
end

if ~exist('s.outstem','var') 
    fprintf('ERROR: no output stem specified') 
    qoe; return
end

if ~exist('s.inplaneres','var') 
    fprintf('ERROR: must specify an in-plane resolution')
    errs = 1;
end

if ~exist('s.betplaneres','var') 
    fprintf('ERROR: must specify a between-planes resolution')
    errs = 1;
end

if ~exist('s.TR','var') 
    s.TR = 1;
    fprintf('INFO: no TR specified ... using %i seconds. \n',s.TR);
end

if(errs) 
    echo 'ERRORS detected ... aborting'
    qoe; return;
end

return
%%%%%%%%%%%%--------------%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%--------------%%%%%%%%%%%%%%%%%%
function arg1err;   end
echo 'ERROR: flag flag requires one argument'
qoe; 
return
%%%%%%%%%%%%--------------%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%--------------%%%%%%%%%%%%%%%%%%
function usage_exit;
fprintf('USAGE: mc-afni')
fprintf('Options:';)
fprintf('   -i stem : input  volume ')
fprintf('   -ipr mm : in-plane resolution')
fprintf('   -bpr mm : between-plane resolution')
fprintf('   -o stem : output volume ')
fprintf('   -t stem : target (input volume)')
fprintf('   -toff off  : target volume off   (targoff)')
fprintf('   -session dir  : afni session directory (afnisession)')
fprintf('   -prefix  name : afni prefix            (procid)')
fprintf('   -nocleanup    : do not delete temporary files')
fprintf('   -scriptonly scriptname   : don''t run, just generate a script')
fprintf('   -version : print version and exit')
qoe;
    return
