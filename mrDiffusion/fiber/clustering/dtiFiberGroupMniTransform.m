function dtiFiberGroupMniTransform(data_directory, fgfilename)

%Input is a file with a fiber group
%can be either .mat or .pdb file
%It is assumed that is is located in dtidir/fibers
%Output is the same fiber structure tranformed into MNI space. 

%ER 04/2008
[pathstr, name, ext, versn] = fileparts(fgfilename); 


    dt6File=fullfile(data_directory, 'dt6.mat');
    [sn, def]=dtiComputeDtToMNItransform(dt6File);
    
        
    filename=fullfile(data_directory, 'fibers', fgfilename);

    
    if strcmp(ext, '.pdb')
    [fg,filename] = mtrImportFibers(filename, eye(4));
    elseif strcmp(ext, '.mat')
        load(filename);
    else
display('Only .mat and .pdb types are supported for fgfilename'); 
    end
    
        
    fg = dtiXformFiberCoords(fg, def); %fg_sn = dtiXformFiberCoords(fg, def);

    coordinateSpace='MNI'; versionNum=1;
    newfilename=[filename(1:end-4) 'MNI'];
    save(newfilename, 'fg', 'coordinateSpace', 'versionNum');
    


