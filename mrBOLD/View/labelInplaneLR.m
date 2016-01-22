function vw = labelInplaneLR(vw)
% vw = labelInplaneLR(vw);
%
%
% USAGE:
%   Once the nifti has been loaded into the view, call this function to
%   add the labels to the view.
%
% INPUT:
%   View with the nifti already loaded.
%
%
% OUTPUT:
%   View with the labels added.
%
% Adds text underneat the axes of an inplane window informing the user
% which side is left and which is right, based in information in the I-file
% header from the inplanes.
%
% written 03/11/04 by ras.
if ~exist('vw','var') || isempty(vw), vw=getSelectedInplane; end

if ~isequal(vw.viewType,'Inplane')
    error('Sorry, this requires an Inplane view ... hence the name. :)');
end

if ~isfield(vw,'ui')  % doesn't work w/ hidden views either
    error('This is a UI function and doesn''t work with hidden views.');
end

%New method:
% 1. Check the direction of the data matrix passed in
% 2. Based on the direction strings and the slice dimension, add the
% necessary labels
% 3. Remember that the 

%Let's find out the orientation of our nifti

vectorString = niftiCurrentOrientation(viewGet(vw,'anatomynifti'));

%Now that we have the vector string, we know that it is formatted in Y, X, Z
% Thus, we can make assumptions about what we put in to dirLabel
%Let's find the directions 
Rdim = niftiFindDimOfString(vectorString,'R');
Adim = niftiFindDimOfString(vectorString,'A');
Sdim = niftiFindDimOfString(vectorString,'S');

%Let's now create the proper label
if (strcmp(vectorString(Rdim),'R'))
    %We have an R, so the right side is Right because of difference between patient and scanner:
    dirTextRL = 'Left  \leftrightarrow  Right';
else
    %We have an L, so the right side is Left:
    dirTextRL = 'Right  \leftrightarrow  Left';
end

if (strcmp(vectorString(Adim),'A'))
    %We have an A, so the left side is Anterior:
    dirTextAP = 'Ant  \leftrightarrow  Pos';
else
    %We have a P, so the left side is Posterior:
    dirTextAP = 'Pos  \leftrightarrow  Ant';
end

if Rdim == viewGet(vw,'slicedim')
    %This is a sagittal slice, so use A-P along the x axis
    sagFlag = 1;
else
    sagFlag = 0;
end
    
% 05/06/05 ras: 
% further change of strategy:
% since Tex is nicer to show the little arrows,
% I'm going to use that -- but can't use uicontrols
% for this. So, I do it a slightly messy way, making 
% invisible axes and setting the label as text:
textPos = get(vw.ui.mainAxisHandle,'Position');
textPos = [textPos(1) textPos(2)-0.04 0.725 0.06];
h1 = axes('Position',textPos,'Visible','off');
AX = axis;
if sagFlag==1
    h2 = text(AX(1)+(AX(2)-AX(1))/2,.4,dirTextAP);
else
    h2 = text(AX(1)+(AX(2)-AX(1))/2,.4,dirTextRL);
end
set(h2,'FontSize',14,'FontName','Helvetica',...
    'HorizontalAlignment','center');

% We should also allow the user to set this uicontrol from the
% pulldown menu, and save the result somehow?
% sure -- as a first step, we'll store it as a pref in the view:
vw.ui.dirLabel.textRL = dirTextRL;
vw.ui.dirLabel.textAP = dirTextAP;
vw.ui.dirLabel.textHandle = h2;
vw.ui.dirLabel.axisHandle = h1;
vw.ui.dirLabel.visible = 'on';

return
% /---------------------------------------------------------/ %


