bd = '/biac3/wandell4/data/reading_longitude/dti_y1/';
%d = dir([bd '*0*']); subDirs = {d.name};
% subDirs = {'am040925','bg040719','crb040707','ctb040706','da040701','es041113',...
% 'hy040602','js040726','jt040717','ks040720','lg041019',...
% 'lj040527','mb041004', 'md040714','mh040630','mho040625','mm040925' ...
% 'nf040812','pt041013','rh040630','rs040918','sg040910',...
% 'sl040609','sy040706','tk040817','tv040928','vh040719','vr040812'};

subDirs = {'mh040630'}; %subDirs = {'kj040929'}; %{'ao041022'}; %This subject was left out?

distThresh = 2;
lName = 'scoredFG_MTproject_100k_200_5_top1000_LEFT_clean';
rName = 'scoredFG_MTproject_100k_200_5_top1000_RIGHT_clean';
for(ii=1:numel(subDirs))
    dd = fullfile(bd, subDirs{ii}, 'dti06', 'fibers', 'MT');
    lfg = dtiReadFibers(fullfile(dd,lName));
    rfg = dtiReadFibers(fullfile(dd,rName));
    lEnd = zeros(3,numel(lfg.fibers));
    rEnd = zeros(3,numel(rfg.fibers));
    % NOTE: we assume that the callosal endpoint is 'end' rather than '1'.
    % This seems to be true, but we should check...
    for(jj=1:numel(lfg.fibers))
        lEnd(:,jj) = lfg.fibers{jj}(:,end-1);
    end
    for(jj=1:numel(rfg.fibers))
        rEnd(:,jj) = rfg.fibers{jj}(:,end);
    end
    [lInd, lDist] = nearpoints(lEnd, rEnd);
    [rInd, rDist] = nearpoints(rEnd, lEnd);
    lHomInds = lDist<distThresh.^2;
    rHomInds = rDist<distThresh.^2;
    fg = dtiNewFiberGroup([lName '_hom'], [20 200 100], [], [], {lfg.fibers{unique(find(lHomInds))}});
    dtiWriteFiberGroup(fg, fullfile(dd, fg.name));
    fg = dtiNewFiberGroup([lName '_het'], [20 100 200], [], [], {lfg.fibers{unique(find(~lHomInds))}});
    dtiWriteFiberGroup(fg, fullfile(dd, fg.name));
    fg = dtiNewFiberGroup([rName '_hom'], [100 200 20], [], [], {rfg.fibers{unique(find(rHomInds))}});
    dtiWriteFiberGroup(fg, fullfile(dd, fg.name));
    fg = dtiNewFiberGroup([rName '_het'], [200 100 20], [], [], {rfg.fibers{unique(find(~rHomInds))}});
    dtiWriteFiberGroup(fg, fullfile(dd, fg.name));
end