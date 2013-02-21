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
global mrSESSION
%TODO: Remove global variables that are unused.

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

[vectorString, xform] = niftiCurrentOrientation(viewGet(vw,'anatomynifti'));

%Now that we have the vector string, we know that it is formatted in Y, X, Z
% Thus, we can make assumptions about what we put in to dirLabel
%Let's find the directions 
Rdim = niftiFindDimOfString(vectorString,'R');
Adim = niftiFindDimOfString(vectorString,'A');
Sdim = niftiFindDimOfString(vectorString,'S');

%Let's now create the proper label
if (strcmp(vectorString(Rdim),'R'))
    %We have an R, so the left side is Right:
    dirTextRL = 'Right  \leftrightarrow  Left';
else
    %We have an L, so the left side is Left:
    dirTextRL = 'Left  \leftrightarrow  Right';
end

if (strcmp(vectorString(Rdim),'A'))
    %We have an A, so the left side is Anterior:
    dirTextAP = 'Ant  \leftrightarrow  Pos';
else
    %We have a P, so the left side is Posterior:
    dirTextAP = 'Pos \leftrightarrow  Ant';
end

if Rdim == viewGet(vw,'slicedim')
    %This is a sagittal slice, so use A-P along the x axis
    sagFlag = 1;
else
    sagFlag = 0;
end

%TODO: Change the location that this data is stored in from mrSESSION to
%the view
% 
% % read dir text:
% % First see if it's saved in mrSESSION, and if not, try  I-files
% if checkfields(mrSESSION, 'dirLabel')
%     dirTextRL = mrSESSION.dirLabel.textRL;
%     dirTextAP = mrSESSION.dirLabel.textAP;
%     sagFlag = mrSESSION.dirLabel.sagittalFlag;
% else
%     % find first dicom for the inplanes:
%     allIfileNames = sessionGet(mrSESSION, 'inplanepath');
%     if isempty(allIfileNames)
%         disp('Sorry, can''t determine Inplane directions.')
%         return
%     else
%         [dirTextRL, dirTextAP, sagFlag] = ifilesDirectionText(allIfileNames);
%     
%         % store results for later (so we don't need the I-files)
%         mrSESSION.dirLabel.textRL = dirTextRL;
%         mrSESSION.dirLabel.textAP = dirTextAP;
%         mrSESSION.dirLabel.sagittalFlag = sagFlag;
%         saveSession(0);
%     end
% end
    
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




% /---------------------------------------------------------/ %
function [dirTextRL, dirTextAP, sagFlag] = ifilesDirectionText(allIfileNames)
% return direction indicating whether left/right in I-files reflects
% l/r or r/l in real-world co-ordinates, as well as a/p, p/a.
% broke off as a subroutine, as suggested.
% NOTE: returns a TeX string, which makes it look nice,
% but is not compatible with Matlab6.5 uicontrols (you can
% make a text object, or xlabel/ylabel/title to get it to work).
% ras, 05/06/06.

% initialize variables
sagFlag = 0;
dirTextRL = '';
dirTextAP = '';

if isempty(allIfileNames)
    % If there are no Ifiles around, leve the labels null
    return
end

% if we got here, there are Ifiles to read
firstIfile = allIfileNames{1};  
tmp=[]; im_hdr=[];
try
    [tmp,tmp,tmp,im_hdr] = readIfileHeader(firstIfile);
catch 
    fprintf('Problem Labeling Inplanes: \n Can''t find good Ifiles to determine directions');
    dirTextRL = '';
    dirTextAP = '';
end

% how I determine which side is which:
% I compare two fields from the image header, tlhc_R, and trhc_R, which
% give the coords in the real world R/L direction of the upper left hand
% corner and upper right hand corner of the image, respectively. By GE
% conventions, more positive in R/L dir means further right, so if the
% right-hand corner value is less than the left-hand corner value, then the
% image is L/R flipped:
%
% ras, 05/06/05: I try to make this work nicer,
% by figuring out both the left-right direction,
% and the ant-pos, and letting the user set
% the label (Under view menu)
if (~isempty(tmp))
    lrFlipped = (im_hdr.trhc_R < im_hdr.tlhc_R);
    
    if lrFlipped, 
        dirTextRL = 'Right  \leftrightarrow  Left';
    else 
        dirTextRL = 'Left  \leftrightarrow  Right';
    end
    
    % allow fudge factor of 10mm: less than this,
    % and consider them as roughly sagittal
    if abs(im_hdr.trhc_R - im_hdr.tlhc_R) < 10
        dirTextRL = '(Roughly Sagittal)';
        sagFlag = 1; 
        % used below, when deciding which label to use
    end
    
    
    % Do the same for the Anterior/Posterior direction
    if (im_hdr.trhc_A < im_hdr.tlhc_A)
        dirTextAP = 'Ant  \leftrightarrow  Pos';
    else
        dirTextAP = 'Pos  \leftrightarrow  Ant';
    end
    
    % allow fudge factor of 10mm: less than this,
    % and consider them as roughly sagittal
    if abs(im_hdr.trhc_A - im_hdr.tlhc_A) < 10
        dirTextAP = '(Roughly Coronal/Axial)';
        % used below, when deciding which label to use
    end
    
end

return

