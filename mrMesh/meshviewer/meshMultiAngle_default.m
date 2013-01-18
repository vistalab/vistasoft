function img = meshMultiAngle(msh)
% Sort of a cross between excelReport2 and meshMultiAngles.
% Makes a montage image of the 5 views and adds a scalebar.

mrGlobals;
cbarFlag=1;
% Script to generate screenshots 
% Saves in current dir: 

viewList={'back','front','left','right','bottom','top'};
viewVectors={[pi -pi/2 0],[pi pi/2 0],[pi 0 0],[0 0 pi],[pi/2 -pi/2 0],[-pi/2 -pi/2 0]};
if (ieNotDefined('view'))   
    view=getSelectedVolume;
end

idList = viewGet(view,'allwindowids');
thisID=view.meshNum3d;

for thisView=1:length(viewList);
    cam.actor=0; 
    cam.rotation=rotationMatrix3d(viewVectors{thisView})
    mrMesh(msh.host,msh.id,'set',cam)
    %date_string=datestr(now,30);
    %dt=dataTYPES(view.curDataType).name;
    %scanNum=int2str(getCurScan(view));
    %mt=meshTypes{v.meshNum3d};
    %filename=fullfile(pwd,[dt,'_',scanNum,'_',date_string,'_',viewList{thisView},'.bmp'])
    %c.filename=fullfile(pwd,'test.bmp');
    
    pause(2);
    images{thisView} = mrmGet(msh, 'screenshot') ./ 255;

    
    
         
end
% make the montage image
img = imageMontage(images, 3,2);

% if specified, display img in a figure and add View's cbar
if cbarFlag
    hfig = figure('Color', 'w');
    imshow(img);
    
    % find the mrVista 1.0 view for the cbar
    gray = getSelectedGray;
    
    if isempty(gray)
        myWarnDlg('No colorbar to attach to image.')
    else
        h = gray.ui.colorbarHandle;
        set(gca, 'Position', [0 .2 1 .8]);
        hcbar = subplot('Position', [.2 .04 .6 .04]);
        tmpH = findobj('Type', 'Image', 'Parent', h);
        cbarImg = get(tmpH, 'CData');
        x = get(tmpH, 'XData'); y = get(tmpH, 'YData');
        
        himg = imagesc([x(1) x(end)], [y(1) y(end)], cbarImg);         
        
        set(hcbar, 'Box', 'off', 'Visible', get(h, 'Visible'), ...
            'XTick', get(h, 'XTick'), 'YTick', get(h, 'YTick'), ...
            'XTickLabel', get(h, 'XTickLabel'), ...
            'YTickLabel', get(h, 'YTickLabel'), ...
            'DataAspectRatio', get(h, 'DataAspectRatio'), ...
            'DataAspectRatioMode', get(h, 'DataAspectRatioMode'), ...
            'PlotBoxAspectRatio', get(h, 'PlotBoxAspectRatio'), ...
            'PlotBoxAspectRatioMode', get(h, 'PlotBoxAspectRatioMode'));
        ttl = get(h, 'Title');
        
        if ishandle(ttl) % a title or xlabel exists, reproduce it
            title(get(ttl, 'String'), 'FontSize', 12);
        end
        
        % Add in some more information: 
        infoText=[viewGet(gray,'homedir'),' Scan:',int2str(viewGet(gray,'curscan'))];
        xlabel(infoText);
        
        
        
        mode = sprintf('%sMode', gray.ui.displayMode);
        nG = gray.ui.(mode).numGrays;       
        colormap(gray.ui.(mode).cmap(nG+1:end,:));
    end
end

% % save / export if a path is specified
% if ~notDefined('savePath')
%     savePath = fullpath(savePath);
%     [p f ext] = fileparts(savePath);
%     if isequal(lower(ext),'.ppt')
%         % export to a powerpoint file
%         fig = figure; imshow(img);
%         [ppt, op] = pptOpen(savePath);
%         pptPaste(op,fig,'meta');
%         pptClose(op,ppt,savePath);
%         close(fig);
%         fprintf('Pasted image in %s.\n', fname);
%     else
%         % export to a .png image in a directory
%         if isempty(f), f=sprintf('mrMesh-%s',datestr(clock)); end
%         if isempty(ext), ext = '.png'; end
%         fname = fullfile(p,[f ext]);
%         if cbarFlag
%             % export the figure w/ the cbar included
%             exportfig(hfig, fname, 'Format','png', 'Color','cmyk', ...
%                       'width',3.5, 'Resolution',450);
%         else
%             % write directly to the image
%             imwrite(img, fname, 'png');
%         end
%         fprintf('Saved montage as %s.\n', fname);
%     end
% else % save to pwd
% %         % export to a pwd-mrMesh-date.png image in current directory
% %         pwdname=pwd;ll=length(pwdname)
% %         f=sprintf('%s-mrMesh-%s',pwdname(ll-4:ll),datestr(now,1));ext = '.png';
% %         fname = [f ext]
% %         udata.rgb = img;
% %         imwrite(udata.rgb, fname);
% %         fprintf('Saved montage as %s.\n', fname);
% end

return

