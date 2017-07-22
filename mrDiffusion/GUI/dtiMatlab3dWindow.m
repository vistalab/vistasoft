function handles = dtiMatlab3dWindow(handles,zImX,zImY,zImZ,zIm,yIm,yImX,yImY,yImZ,xIm,xImX,xImY,xImZ); 
%
%  handles = dtiMatlab3dWindow(handles,zImX,zImY,zImZ,zIm,yIm,yImX,yImY,yImZ,xIm,xImX,xImY,xImZ); 
%
%Author: Dougherty, Wandell
%Purpose:
%   Show ROIs and FGs and images in a Matlab 3D window.  We used to use
%   this a lot before we started relying on the mrMesh window.
%   The image data are obtained in the dtiRefresh callback and then passed
%   in.  

%   Programming Notes:
%   Getting the images requires a bit of work, so we don't repeat the
%   process in each display sub-routine.  But, that makes the modules less
%   modular.

if ~exist('handles','var')||isempty(handles), error('dtiFiberUI handles required.'); end

showTheseFgs = dtiFGShowList(handles);

% Reopen the 3D figure if it was closed.
if ~ishandle(handles.fig3d)
    handles.fig3d = figure;
end

figure(handles.fig3d);
set(handles.fig3d, 'NumberTitle', 'off');
set(handles.fig3d, 'Name', [handles.title,' 3D']);
oldCameraPos = get(gca(handles.fig3d), 'CameraPosition');
hold off;

%grid on
% Show z-slice 
if ( get(handles.rbAxial,'Value') )
    h = surf(zImX,zImY,zImZ,zIm);
    set(h,'FaceColor','interp','EdgeColor','interp');
    colormap(gray);
    hold on;
end

% Show y-slice
if ( get(handles.rbCoronal,'Value') )
    h = surf(yImX,yImY,yImZ,yIm);
    set(h,'FaceColor','interp','EdgeColor','interp');
    colormap(gray);
    hold on;
end

% Show x-slice
if ( get(handles.rbSagittal,'Value') )
    h = surf(xImX,xImY,xImZ,xIm);
    set(h,'FaceColor','interp','EdgeColor','interp');
    colormap(gray);
    hold on;
end

set(gca,'Color',[0,0,0], 'CameraViewAngleMode','manual', 'CameraViewAngle',10);
axis equal;
axis([-70,70, -110,70, -40,80]);
xlabel('X (mm)'); ylabel('Y (mm)'); zlabel('Z (mm)');
hold on;

for(grpNum=showTheseFgs)
    fg = handles.fiberGroups(grpNum);
    if(fg.visible)
        for(ii=1:length(fg.fibers))
            % The fibers are already stored in standard coordinates, so no
            % transform is needed.
            h = plot3(fg.fibers{ii}(1,:), fg.fibers{ii}(2,:), fg.fibers{ii}(3,:), '-');
            curRgb = fg.colorRgb(1:3)./255+(rand(1)*.1-0.05);
            curRgb = max([0 0 0],min(curRgb,[1 1 1]));
            set(h, 'Color', curRgb);
            set(h, 'LineWidth', abs(fg.thickness));
        end
    end
end
hold off;

return;