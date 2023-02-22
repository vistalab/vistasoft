function labels=dtiGetMoriLabels(short)

%ER 11/2009 wrote it

tdir = fullfile(fileparts(which('mrDiffusion.m')), 'templates');
labels = readTab(fullfile(tdir,'MNI_JHU_tracts_prob.txt'),',',false);
labels = labels(1:20,2);
if exist('short', 'var') && short
labels={'ATR_L', 'ATR_R', 'CST_L', 'CST_R', 'CCG_L', 'CCG_R', 'CHC_L','CHC_R', 'Forceps Major', 'Forceps Minor', 'IFO_L', 'IFO_R', 'ILF_L', 'ILF_R', 'SLF_L', 'SLF_R', 'UF_L', 'UF_R', 'SLF_t_L', 'SLF_t_R' }';
end
