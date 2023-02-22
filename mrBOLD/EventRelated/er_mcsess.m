function er_mcsess(varargin);
% 
% er_mcsess(varargin);
%
% Another unix script slowly being integrated into matlab. Attempt to call 
% AFNI motion-correction algorithm from within mrLoadRet. Not working yet.
% 
%~/bin/csh -f
% mc-sess - motion correction
%
% Id: mc-sess,v 1.1 2003/03/04 21:22:09 greve Exp 
VERSION    = 'Id: mc-sess,v 1.1 2003/03/04 21:22:09 greve Exp '

ScriptOnly = 0;
fsd = 'bold';
mcmethod   = 'afni'
targoff    = 0;
funcstem   = f;  % stem of functional volume
funcmcstem = (); % stem of functional motion-corrected volume
PWDCMD = 'getpwdcmd';
targnthrun = 1;  % use nth run as target
nolog = 0;
RunListFile = ();

if (nargin == 0)  
    usage_exit;
    return;
end

n = 'echo varargin | grep version | wc -l' 
if(n ~= 0)  
    echo VERSION
    return;
end

n = 'echo varargin | grep citation | wc -l' 
if(n ~= 0)  
    sprintf( 'Those using the AFNI motion correction should cite:')
    sprintf( '  RW Cox and A Jesmanowicz.')
    sprintf( '  Real-time 3D image registration for functional MRI.')
    sprintf( '  Magnetic Resonance in Medicine, 42: 1014-1018, 1999.')
    return;
end

SessList = 'getsesspath varargin';
if(status || %SessList == 0)  
    sprintf(SessList)
    return;
end

 parse_args;

if isempty(funcmcstem)   funcmcstem = fmc;   
    
    check_params;
    
    % Create a log file %
    if(~ nolog )  
        mkdir -p log
        LF = 'pwd'/log/mc-fsd-sess.log
        rm -f fidlog
        touch fidlog
    else
        LF = /dev/null
    end
    sprintf('Logfile is %s',fidlog)
    
    fprintf(fidlog,'mc-sess')
    fprintf(fidlog,'%s',VERSION) 

    uname -a          >> fidlog
    date              >> fidlog
    sprintf( 'varargin'      >> fidlog
    
    %% go through each session %%
    for sess (SessList)
    
    sessid = 'basename sess';
    echo '-------------------------------------------' |& tee -a fidlog
    echo 'sess ' |& tee -a fidlog
    
    if(~ -d sess)  
        echo 'ERROR: sess does not exist'   |& tee -a fidlog
        return;
    end
    
    cd sess/fsd
    
    %% get resolutions %
    inplaneres  = 'cat seq.info | awk '{if(1 == 'rowpixelsize') print 2}'';
        betplaneres = 'cat seq.info | awk '{if(1 == 'slcpixelsize') print 2}'';
            TR = 'cat seq.info | awk '{if(1 == 'TR') print 2}'';
                
                if(%inplaneres == 0)  
                    echo 'ERROR: seq.info file does not appear to be formated correctly'
                    echo '       Try running fixseqinfo-sess.'
                    return;
                end
                
                if(%RunListFile == 0)  
                    RunList = 'getrunlist .';
                    if(status || %RunList == 0)  
                        echo 'ERROR: sess/fsd has no runs'  |& tee -a fidlog
                        return;
                    end
                else
                    if(~ -e RunListFile)  
                        echo 'ERROR: cannot find runlistfile RunListFile'
                        return;
                    end
                    RunList = 'cat RunListFile';
                end
                echo 'RunList: RunList' |& tee -a fidlog
                
                if ScriptOnly   
                    if(~ -d scripts) mkdir scripts
                        scriptfile = scripts/run-mc
                        rm -f scriptfile
                        touch scriptfile
                        echo '%...~/bin/csh -f' >> scriptfile 
                        echo 'cd ..'          >> scriptfile 
                        chmod a+x scriptfile
                    end
                    
                    if length(RunList) < targnthrun
                        fprintf(2,'ERROR: sessid target run (targnthrun) exceeds number of runs %i\n',length(RunList));
                        return;
                    end
                    
                    targstem = RunList[targnthrun]/funcstem
                    for run (RunList)  
                    fprintf(2,'  ------- ************************** -----------\n')
                    fprintf(2,'  ------- Motion Correcting Run %i -----------\n',run)
                    fprintf(2,'  ------- ************************** -----------\n')
                    fprintf(fidlog,'  ------- ************************** -----------\n')
                    fprintf(fidlog,'  ------- Motion Correcting Run %i -----------\n',run)
                    fprintf(fidlog,'  ------- ************************** -----------\n')
                    date |& tee -a fidlog
                    instem  = run/funcstem
                    outstem = run/funcmcstem
                    cmd = (mc-mcmethod -i instem -o outstem ...
                    -t targstem -toff targoff);
                    cmd = (cmd -ipr inplaneres -bpr betplaneres -TR TR)
                    if ~ScriptOnly
                        echo cmd |& tee -a fidlog
                        cmd |& tee -a fidlog
                        if(status) return;
                            
                            % Create the external regresssor file %
                            sprintf('INFO: Making external regressor from mc params' )
                            cmd = (mcparams2extreg -mcfile outstem.mcdat -northog 6)
                            cmd = (cmd -extreg run/mcextreg)
                            echo cmd |& tee -a fidlog
                            cmd |& tee -a fidlog
                            if(status) return;
                                
                            else
                                echo cmd >> scriptfile
                            end
                        end
                        echo '\n\n' |& tee -a fidlog
                        
                        if ScriptOnly
                            echo '\n\n' >> scriptfile
                        end
                        
                    end
                    
    fprintf(fidlog,'%s',date);
    fprintf(2,'mc-sess completed SUCCESSFULLY')
    fprintf(fidlog,'mc-sess completed SUCCESSFULLY');
                    
return;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%--------------%%%%%%%%%%%%%%%%%%
function s = parse_args(args);
% Parse the input args

while( length(args) > 0 )
 	flag = args(1);
	args = args{2:end};   
	switch(flag)
		case '-ssd',
		
		case '-fsd',
		if ( length(args) == 0)  arg1err;
		fsd = varargin[1]; args = args{2:end};;
		
		
		case '-toff',
		if ( length(args) == 0)  arg1err;
		targoff = varargin[1]; args = args{2:end};;
		
		
		case '-fstem',
		if ( length(args) == 0)  arg1err;
		funcstem = varargin[1]; args = args{2:end};;
		
		
		case '-fmcstem',
		if ( length(args) == 0)  arg1err;
		funcmcstem = varargin[1]; args = args{2:end};;
		
		
		case '-targnthrun',
		if ( length(args) == 0)  arg1err;
		targnthrun = varargin[1]; args = args{2:end};;
		
		
		case '-runlistfile',
		case '-rlf',
		if ( length(args) == 0)  arg1err;
		RunListFile = varargin[1]; args = args{2:end};;
		
		case '-method',
		if ( length(args) == 0)  arg1err;
            mcmethod = varargin[1]; args = args{2:end};;
            if(mcmethod ~= 'afni')  
                echo 'ERROR, only afni supported'
                return;
            end
            
		case '-nolog',
            nolog = 1;
            
            
		case '-verbose',
            verbose = 1;
            
            
		case '-echo',
            echo = 1;
            
            
		case '-debug',
            verbose = 1;
            echo = 1;
            
            
		case '-scriptonly',
            ScriptOnly = 1;         
            
		case '-umask',
            if ( length(args) == 0)  arg1err;
                umaskarg = '-umask varargin[1]';
                umask varargin[1]; args = args{2:end};;
                       
        case '-s',
        case '-sf',
        case '-d',
        case '-df',
        case '-g',
            args = args{2:end};;
            % ignore getsesspath arguments 
            
        case '-cwd',
            % ignore getsesspath arguments 
            
        otherwise,
           % don't worry about weird args for now     
	end
end
    
return
%%%%%%%%%%%%--------------%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%--------------%%%%%%%%%%%%%%%%%%
function check_params(SessList)

if (length(SessList) == 0)  
    error('ERROR: no sessions specified~')
    return
end

return
%%%%%%%%%%%%--------------%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%--------------%%%%%%%%%%%%%%%%%%
function arg1err
sprintf('ERROR: flag flag requires one argument')
return
%%%%%%%%%%%%--------------%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%--------------%%%%%%%%%%%%%%%%%%
function usage_exit
sprintf( '')
sprintf( 'USAGE: mc-sess')
sprintf( '')
sprintf( 'Optional Arguments:');
sprintf( '   -method  mcmethod  : afni')
sprintf( '   -targnthrun n      : use nth run as target (default=1)')
sprintf( '   -toff m            : target image off  (targoff)')
sprintf( '   -fstem stem        : stem of output motion-corrected volume (fmc)')
sprintf( '   -fmcstem stem      : stem of output motion-corrected volume (fmc)')
sprintf( '   -umask umask       :   unix file permission mask')
sprintf( '   -version           : print version and exit')
sprintf( '   -rlf  runlistfile  : only process those in the runlist file')
sprintf( '')
sprintf( 'Session Arguments (Required)')
sprintf( '   -sf sessidfile  ')
sprintf( '   -df srchdirfile ')
sprintf( '   -s  sessid      ')
sprintf( '   -d  srchdir     ')
sprintf( '   -fsd dir        (optional - default = bold)')
sprintf( '')
return
