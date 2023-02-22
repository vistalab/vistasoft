%% t_gifti_1
%
% Introduction to the gifti reader/writer.  
% GIFTI is from
% http://www.artefact.tk/software/matlab/gifti/
% https://github.com/nno/matlab_GIfTI
%
% The example here executes the gifti example from their web page
%
% (c) Stanford VISTA Team 

% Help:
%
%{
 % The gii files in the example can be downloaded into the
 % local/ folder this way

 fullFolderName = fullfile(vistaRootPath,'local');
 rdt = RdtClient('vistasoft');
 rdt.crp('/vistadata/gifti/BV_GIFTI/Base64'); 
 
 % Download the two test files.
 surfFile = rdt.readArtifact('sujet01_Lwhite.surf',...
    'type','gii',...
    'destinationFolder',fullFolderName);

 shapeFile = rdt.readArtifact('sujet01_Lwhite.shape',...
    'type','gii',...
    'destinationFolder',fullFolderName);
%}

%%  Go to the local folder.  
% If you don't already have the gifti files, download them as above.

chdir(fullfile(vistaRootPath,'local'));

%% 1. Run through the gifti team example
if exist('sujet01_Lwhite.surf.gii','file')
    g = gifti('sujet01_Lwhite.surf.gii');
else
    error('File not found.  See comment help');
end

% Blue shaded
mrvNewGraphWin; plot(g);  

% The color overlay values are determined by an color map and a single
% scaling (I think).
if exist('sujet01_Lwhite.shape.gii','file')
    gg = gifti('sujet01_Lwhite.shape.gii');
else
    error('File not found.  See comment help');
end

mrvNewGraphWin; h = plot(g,gg);

%% End


