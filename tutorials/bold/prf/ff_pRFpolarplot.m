function   figHandle =  ff_pRFpolarplot(groupcov,vfc)
% take an image and the vfc struct from rmCoveragePlot and make a polar
% coverage plot.  much code borrowed from serges coverageplot stuff



% will assume data is already normalized or not
%     img = groupcov ./ rfMax;
    img =groupcov;
%     stimulus was in a circular aperture
    mask = makecircle(length(img));
%     sets all values outside circle to 0 and inside to 1
    img = img .* mask;
%  set image siz
% visual field indices
    x = single( linspace(-vfc.fieldRange, vfc.fieldRange, vfc.nSamples) );
    [X,Y] = meshgrid(x,x);
%     not really sure this is necessary
%         imagesc([-12,12],[-12,12],img);
    imagesc(X(1,:), Y(:,1), img);
    
    %  more y flipping.  no idea if this should be here.
    %  does have to be here!
    set(gca, 'YDir', 'normal');
    grid on
    
    colormap(vfc.cmap);
    colorbar;
    
    % start plotting
    hold on;
    
    % add polar grid on top
    p.ringTicks = (1:3)/3*vfc.fieldRange;
    p.color = 'w';
    polarPlot([], p);
    
%     add prf centers to group plot?
    vfc.addCenters = 0;
    % % add pRF centers if requested
    if vfc.addCenters,
        %             for each subject add the prf centers
        for k=1:length(rmstouse)
            
            inds = rm{rmstouse(k)}.ecc < vfc.fieldRange;
            plot(rm{rmstouse(k)}.x0(inds), rm{rmstouse(k)}.y0(inds), '.', ...
                'Color', [.5 .5 .5], 'MarkerSize', 4);
        end
        
    end
    
    
    % scale z-axis
    % if vfc.normalizeRange
    % 	if isequal( lower(vfc.method), 'maximum profile' )
    % 		caxis([.5 1]);
    % 	else
    % 	    caxis([0 1]);
    % 	end
    % else
    %     if min(RFcov(:))>=0
    %         caxis([0 ceil(max(RFcov(:)))]);
    %     else
    %         caxis([-1 1] * ceil(max(abs(RFcov(:)))));
    %     end
    % end
    axis image;   % axis square;
    xlim([-vfc.fieldRange vfc.fieldRange])
    ylim([-vfc.fieldRange vfc.fieldRange])
    
    
    
    colormap(vfc.cmap);
    colorbar;
    
%     title(rm{1}.name, 'FontSize', 24, 'Interpreter', 'none');
%     saveas(gcf,[saveDir rois{r} '.group.coverage.fig'],'fig');
%     saveas(gcf,[saveDir rois{r} '.group.coverage.png'],'png');
    
figHandle = gcf; 



end