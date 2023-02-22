% This script copies the datasets into a working directory and executes% the script register% GB, MBS% fileList is the subject dirs that are to be corrected
%         fileList = {'at041009','at041016','ctr040710','ctr040717',...%                 'da040722','dh040708','hy040618','hy040808','js040821',...%                 'jt040807','jt040814','ks040811','ks040825','lg041127',...%                 'mb041011','md040721','md040724','mh040721','mh040724',...%                 'mho040714','mho040717','mm041009','nf040812','nf040828',...%                 'pt041115','rd041030','rd041028','rs041009','rsh041009',...%                 'sg040917','sg040925','ss040811','tk040826','tk040901',...%                 'tm041029','tv041028','vh040812','vr040901','vr040914'};
fileList = {'rd20050427'};%   temp dir on biac2
% if isunix% 
%     networkPathTarget = '/biac2/wandell';% 
%     networkPathSource = '/snarp';% 
% else% 
%     networkPathTarget = '\\White\biac2-wandell\';% 
%     networkPathSource = '\\snarp'% 
% end% destinationDir = fullfile(networkPathTarget,'data','reading_longitudinal_study','To_correct');% sourceDir = fullfile(networkPathSource,'u1','data','reading_longitude','fmri');
%   temp dir on tealif isunix    networkPathSource = '/snarp';    networkPathTemp = '/teal/scr1/';else    networkPathSource = '\\snarp'    networkPathTemp = '\\teal\scr1\';endsourceDir = fullfile(networkPathSource,'u1','data','data_archive','fmri','wordPictsLeftRight');tempDir = fullfile(networkPathTemp,'fmri','mcToCorrect');
for i = 1:length(fileList)    source = fullfile(sourceDir,fileList{i});    temp = fullfile(tempDir,fileList{i});    copyfile(source,temp);end
register
%temp dir on biac2
% if isunix%     networkPathTarget = '/biac2/wandell';%     networkPathSource = '/snarp';% else%     networkPathTarget = '\\White\biac2-wandell\';%     networkPathSource = '\\snarp'% end%% destinationDir = fullfile(networkPathTarget,'data','reading_longitudinal_study','To_correct');% finalDir = fullfile(networkPathTarget,'data','reading_longitudinal_study','CorrectedBrains');%temp dir on tealif isunix    networkPathTemp = '/teal/scr1/';    networkPathFinal = '/teal/scr1/';else    networkPathTemp = '\\teal\scr1\'    networkPathFinal = '\\teal\scr1\';endtempDir = fullfile(networkPathTemp,'fmri','mcToCorrect');finalDir = fullfile(networkPathFinal,'fmri','mcCorrected');
copyList = dir(tempDir);
for i = 3:length(copyList)    temp = fullfile(tempDir,copyList(i).name);    final = fullfile(finalDir,copyList(i).name);    copyfile(temp,final);    delete(temp);end
