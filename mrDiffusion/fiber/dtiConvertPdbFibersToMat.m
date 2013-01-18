% dtiConvertFibersToMat.m
% 
% This script takes n .pdb or .Bfloat fiber groups for a group of subjects
% and saves them as .mat files so they can be easily loaded in dtiFiberUI.
%
% HISTORY:
% 07/27/2009 LMP wrote the thing.
%


%%
baseDir = '/biac3/wandell4/data/reading_longitude/';
yr = {'dti_adults'};
subs = {'aab050307','ah051003','am090121','ams051015','as050307','aw040809','bw040922','ct060309','db061209','dla050311'...
    'gd040901','gf050826','gm050308','jl040902','jm061209','jy060309','ka040923','mbs040503','me050126','mo061209',...
    'mod070307','mz040828','pp050208','rfd040630','rk050524','sc060523','sd050527','sn040831','sp050303','tl051015'};

fibers = {'scoredFG_Controls_Mori_Occ_CC_100k_top1000_LEFT'...
    'scoredFG_Controls_Mori_Occ_CC_100k_top1000_RIGHT'...
    'scoredFG_Controls_Mori_Occ_CC_100k_top10000_LEFT'...
    'scoredFG_Controls_Mori_Occ_CC_100k_top10000_RIGHT'...
    'scoredFG_Controls_Mori_Occ_CC_100k_top20000_LEFT'...
    'scoredFG_Controls_Mori_Occ_CC_100k_top20000_RIGHT'};

%%  Loops through subs

for ii=1:length(subs)
    for jj=1:length(yr)
        sub = dir(fullfile(baseDir,yr{jj},[subs{ii} '*']));
        if ~isempty(sub)
            subDir = fullfile(baseDir,yr{jj},sub.name);
            fiberDir = fullfile(subDir,'dti06','fibers','conTrack');
            mFiberDir = fullfile(subDir,'dti06','fibers','conTrack','occ_MORI_clean');
            
            disp(['Processing ' subDir '...']);

            dt = dtiLoadDt6(fullfile(subDir,'dti06','dt6.mat'));
            xform = dt.xformToAcpc;
            
            c = 0;
            for kk=1:numel(fibers)
            c = (c+1);
                filename = fullfile(fiberDir,[fibers{kk} '.pdb']);
                if ~exist(filename) || isempty(filename)
                    filename =fullfile(fiberDir,[fibers{kk} '.Bfloat']);
                end
                [fg,filename] = mtrImportFibers(filename,xform);
                fg.name = fibers{kk};
                if mod(c,2) == 0
                    fg.colorRgb = [255 20 20];
                else
                    fg.colorRgb = [20 20 255];
                end
                dtiWriteFiberGroup(fg,fullfile(mFiberDir,fg.name));
            end

        else disp('No data for this subject');
        end
    end

end
disp('Done!');

