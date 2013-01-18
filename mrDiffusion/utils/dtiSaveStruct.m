function dtiSaveStruct(s, fname)
%
% dtiSaveStruct(s, fname)
%
% Simply saves the fields of the struct s into the mat-file 'fname'. The
% one useful feature is that it saves them *without* the top-level struct.
% Eg, each field of s is saved as a stand-alone variable.
%
% HISTORY:
% 2005.01.27 RFD: wrote it.

cmd = ['save ' fname];
f = fieldnames(s);
for(ii=1:length(f)) 
    cmd = [cmd ' ' f{ii}];
    eval([f{ii} '=s.' f{ii} ';']);
end
eval(cmd);
return;