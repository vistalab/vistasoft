function labels = mrGrayGetLabels(outFileName)
% Returns the new mrGray labels.
% labels = mrGrayGetLabels([outFileName=''])
%
% If outFileName is not empty, then the labels are also saved 
% in a text file (in ITKSnap/ITKGray format).
% 
% HISTORY:
% 2007.12.12 RFD wrote it.

labels.CSF = 1;
labels.subCorticalGM = 2;
labels.leftWhite = 3;
labels.rightWhite = 4;
labels.leftGray = 5;
labels.rightGray = 6;

if(exist('outFileName','var')&&~isempty(outFileName))
  % ITK-SnAP Label Description File File format: 
  % IDX   -R-  -G-  -B-  -A--  VIS MSH  LABEL
  % Fields: 
  %    IDX:   Zero-based index 
  %    -R-:   Red color component (0..255)
  %    -G-:   Green color component (0..255)
  %    -B-:   Blue color component (0..255)
  %    -A-:   Label transparency (0.00 .. 1.00)
  %    VIS:   Label visibility (0 or 1)
  %    IDX:   Label mesh visibility (0 or 1)
  %  LABEL:   Label description 
  fid = fopen(outFileName,'w');
  fprintf(fid,'%d %d %d %d %0.2f %d %d "%s"\n',0,0,0,0,0.0,0,0,'unclassified');
  fprintf(fid,'%d %d %d %d %0.2f %d %d "%s"\n',labels.CSF,255,0,0,1.0,1,0,'CSF');
  fprintf(fid,'%d %d %d %d %0.2f %d %d "%s"\n',labels.subCorticalGM,0,255,0,1.0,1,1,'sub-cortical GM');
  fprintf(fid,'%d %d %d %d %0.2f %d %d "%s"\n',labels.leftWhite,0,0,255,1.0,1,1,'left white');
  fprintf(fid,'%d %d %d %d %0.2f %d %d "%s"\n',labels.rightWhite,255,255,0,1.0,1,1,'right white');
  fprintf(fid,'%d %d %d %d %0.2f %d %d "%s"\n',labels.leftGray,0,255,255,1.0,1,1,'left gray');
  fprintf(fid,'%d %d %d %d %0.2f %d %d "%s"\n',labels.rightGray,255,0,255,1.0,1,1,'right gray');
  fclose(fid);
  
end

return;
