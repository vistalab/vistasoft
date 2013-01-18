function labels = mrGrayReadLabels(lblFileName)
% 
% labels = mrGrayReadLabels([lblFileName=''])
%
% Reads itkGray/itkSnap label text file.
% 
% HISTORY:
% 2008.08.30 RFD wrote it.

if(~exist('lblFileName','var'))
    lblFileName = '';
end
if(isempty(lblFileName)||~exist(lblFileName,'file'))
    [f,p] = uigetfile({'*.lbl','ITKGray/ITKSnap label file'; '*.*','All Files (*.*)'},'Select label file');
    if(isequal(f,0)|| isequal(p,0)), disp('user canceled.'); return; end
    if(isempty(p)), p = pwd; end
    lblFileName = fullfile(p,f);
end


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
fid = fopen(lblFileName,'r');
ii = 0;

while(~feof(fid))
    tmp = fgetl(fid);
    tmp = strtrim(tmp);
    if(~isempty(tmp) && tmp(1)~='#')
        ii = ii+1;
        tmp = regexprep(tmp,'\W*',' ');
        tmp = strrep(tmp,'"','');
        [i,r,g,b,a,v,m,d] = strread(tmp,'%d %d %d %d %f %d %d %s',1);
        % get the whole label (strread will only return the first word):
        ind = strfind(tmp,d{1});
        d = strtrim(tmp(ind:end));
        labels(ii).index = i;
        labels(ii).name = d;
        labels(ii).color = [r g b];
        labels(ii).alpha = a;
        labels(ii).visibility = v;
        labels(ii).meshVis = m;
    end
end

return;
