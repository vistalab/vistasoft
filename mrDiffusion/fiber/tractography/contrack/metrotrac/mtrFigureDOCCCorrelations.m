function mtrFigureDOCCCorrelations(machineDir, saveDir)

subjVec = {'ss040804','mho040625','bg040719','md040714'};
threshVec = [1000];
paramNames = {'kLength','kSmooth','kMidSD'};
midP = [0 18 0.175];
bSaveImages = 1;

for pp = 1:3
    figure;
    for ss = 1:length(subjVec)
        subjDir = [machineDir subjVec{ss}];

        fgDir = [subjDir '/conTrack/resamp_LDOCC'];
        disp(['cd ' fgDir]);
        cd(fgDir);
        % Correlation between CTs
        if(pp==1)
            mtrPlotCorr('cc_-2',threshVec,paramNames,midP,pp,'b'); hold on;
        else
            mtrPlotCorr('cc',threshVec,paramNames,midP,pp,'b'); hold on;
        end
        % Correlation between CTs and STTs
        %mtrPlotCorr('cc_STT',threshVec,paramNames,midP,1,'g'); hold on;
        % Save out the figures to the image dir

        fgDir = [subjDir '/conTrack/resamp_RDOCC'];
        disp(['cd ' fgDir]);
        cd(fgDir);
        % Correlation between CTs
        if(pp==1)
            mtrPlotCorr('cc_-2',threshVec,paramNames,midP,pp,'b'); hold on;
        else
            mtrPlotCorr('cc',threshVec,paramNames,midP,pp,'b'); hold on;
        end
        oldaxis = axis;
        if pp == 1
            axis([-4 1 0 1]);
        else
            axis([oldaxis(1) oldaxis(2) 0 1]);
        end
        % Correlation between CTs and STTs
        %mtrPlotCorr('cc_STT',threshVec,paramNames,midP,1,'g');
    end
    % Save out the figures to the image dir
    set(gcf,'Position',[395   447   289   240]);
    if bSaveImages
        figFilename = fullfile(saveDir,['param_' paramNames{pp} '_corr.png']);
        set(gcf,'PaperPositionMode','auto');
        print('-dpng', figFilename);
    end
end

