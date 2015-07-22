function camBfloatTract2pdb(Bfloattract_filename, output_file)
%
% camBfloatTract2pdb(Bfloattract_filename, output_file)
%
% Converting the streamline/fiber file in Bfloat format into mrDiffusion/pdb format
% 
% INPUT:
% Bfloattract_filename: The full path to Bfloat file containing streamline trajectory
% output_file:          The filename for the output file (either .mat or .pdb format)
% 
% (C) Hiromasa Takemura, CiNet HHS/Stanford Vista Team, 2015

% Load the path in Bfloat format
fg_Bfloat = dtiLoadCaminoPaths(Bfloattract_filename);

% Create fg Structure 
fg = fgCreate;
fg.name = output_file;
fg.fibers = fg_Bfloat.pathways;

% Save file
fgWrite(fg);

return

