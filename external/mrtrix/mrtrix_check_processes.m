function computed = mrtrix_check_processes(files)
%
% Check which mrtrix processes were computed. Returns an array of 0's and
% 1's indicating which process was computed (1) and which one needs to be
% computed (0)
% 
%  computed = mrtrix_check_processes(files)
% 
% INPTU:
%  files - is a strucutre of files containig all the preprocesing files
%          necessary for mrtrix tracktography.
%
% OUTPUT:
%  computed - is a structure containing the same files are the input with
%             value assigned, '0' means not compute, '1' means the process 
%             was computed.
%
% Franco, Ariel, Bob (c) Stanford Vista Team, 2013

fields = fieldnames(files);
for ii = 1:length(fields)
  if exist(files.(fields{ii}),'file') == 2
    computed.(fields{ii}) = 1;
  else
    computed.(fields{ii}) = 0;
  end
end
