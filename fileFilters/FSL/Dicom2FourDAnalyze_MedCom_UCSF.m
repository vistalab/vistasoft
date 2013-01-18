function Scan=Dicom2FourDAnalyze_MedCom_UCSF(Scan,baseDir);
% Scan=Dicom2FourDAnalyze_MedCom_UCSF(Scan);
% where Scan has to be a struct with the fields
% Scan.DirName
% Scan.Slices
% Scan.Volumes
% Scan.Filenames
% Scan.Filename4d
%
% the script will generate a 4danalyze file
% and put the name into the field Scan.Filename4d
% written 2006.01.12 by Mark Schira mark@ski.org

if ~exist('baseDir')
    baseDir = pwd;
end

Directory=[baseDir,filesep,Scan.DirName];
Filename=Scan.Filenames;
Slices=Scan.Slices;
Volumes=Scan.Volumes;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Stuff for fsl
fslBase='/raid/MRI/toolbox/FSL/fsl';
if (ispref('VISTA','fslBase'))
    disp('Setting fslBase to the one specified in the VISTA matlab preferences:');
    fslBase=getpref('VISTA','fslBase');
    disp(fslBase);
end

fslPath=fullfile(fslBase,'bin'); % This is where FSL lives - should also be able to get this from a Matlab pref
reconPath='/raid/MRI/toolbox/Recon'; % required for the recon program to convert .mag files into Analyze format


cd (Directory);

%******************************************************************
%now do the Recon

try
    In3dFileString=' ';
    for thisVol=1:Volumes;
        fistFile=1+(thisVol-1)*Slices;
        filenumbers=[fistFile:fistFile+Slices-1]; %these are the filenumbers of the slices we need
        filestring=' '; %we need a filestring to start with
        for thisSlice=1:Slices
            filestring=sprintf('%s %s%d.DCM',filestring,Filename,filenumbers(thisSlice));
        end
        Out3dVolStr=sprintf('%s%03d.hdr',Filename,thisVol);
        evalStr1=['!medcon -f',filestring,' -c anlz -stacks -o ',Out3dVolStr];
        eval(evalStr1);
        In3dFileString=sprintf('%s m000-stacks-%s%04d.DCM',In3dFileString,Out3dVolStr);
        In3dFileStringb=sprintf('%s m000-stacks-%s%04d.DCM',In3dFileString,Out3dVolStr);
        
    end
    OutVolStr=sprintf('%s_4d.hdr',Filename);
    %Usage: avwmerge <-x/y/z/t> <output> <file1 file2 .......>
    evalStr2=['!/raid/MRI/toolbox/FSL/fsl/bin/avwmerge -t ',OutVolStr,In3dFileString];
    eval(evalStr2);
    Scan.Filename4d=OutVolStr;
    display(['saved ',OutVolStr]);
    
    evalStr=(['! rm m000-stacks*']);
    eval(evalStr);
catch
    display('Warning!! Making4d file failed!');
end
cd (baseDir)


