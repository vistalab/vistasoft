function pts = rxGetACPC(rx, displayFlag, whichPoint);
%
% pts = rxSetACPC([rx], [displayFlag=1], [whichPoint='ac']);
%
% Retrieve AC/PC points which have previously been set using rxSetACPC.
%
% "Retrieving" can mean different things, depending on the displayFlag
% option:
%
% displayFlag==1 means print the coordinates of specified points in the
% standard output (usually command window);
%
% displayFlag==2 means print the coordinates of specified points in a
% mrMessage box;
% 
% displayFlag==3 means center an interpolated 3-view window on the
% specified point. For this case, the 'whichPoint' argument specifies the
% point on which to recenter.
%
% displayFlag==0 means don't display anything, just return the points.
%
% More information on AC/PC alignment is available at:
%	http://white.stanford.edu/newlm/index.php/Anatomical_Methods
% and in the help for rxSetACPC.
%
% INPUTS:
%	rx: mrRx rx struct; searches for a GUI if omitted.
%
%	displayFlag: display option. see above.
%
%	whichPoint: flag to specify whether the AC, PC, or mid-sagittal point
%	is being shown (for displayFlag==3). 
%	Can be an integer flag or string, out of the following:
%		1 or 'ac': set the anterior commissure (AC).
%		2 or 'pc': set the posterior commissure (PC).
%		3 or 'midsag': set the mid-sagittal point in the same coronal as
%						the AC.
%
%
% OUTPUTS:
%   pts: the contents of the rx.acpcPoints field.
%
% ras, 02/08/2008.
cfig = findobj('Tag','rxControlFig');

if ~exist('rx', 'var') | isempty(rx),    rx = get(cfig,'UserData'); end
if notDefined('displayFlag'),	displayFlag = 1;	end
if notDefined('whichPoint'),	whichPoint = 'ac';	end

if ~checkfields(rx, 'acpcPoints')
	error('No AC/PC points set.')
end

pts = rx.acpcPoints; 

switch displayFlag
	case 0,  % silent
		
	case 1,   % print to command line
		fprintf(  '\n\nAC/PC points (row, col, slice):\n' );
		fprintf( '----------------------------------\n' );
		fprintf( 'Anterior Commisure: %s\n', num2str(pts(:,1)') );
		fprintf( 'Posterior Commisure: %s\n', num2str(pts(:,2)') );
		fprintf( 'Mid-Sagittal Point: %s\n', num2str(pts(:,3)') );
		
	case 2,   % display in mrMessage box
		str = [ sprintf(  'AC/PC points (row, col, slice):\n' ) ...
				sprintf( '----------------------------------\n' ) ...
				sprintf( 'Anterior Commisure: %s\n', num2str(pts(:,1)') ) ...
				sprintf( 'Posterior Commisure: %s\n', num2str(pts(:,2)') ) ...
				sprintf( 'Mid-Sagittal Point: %s\n', num2str(pts(:,3)') ) ...
				];
		mrMessage(str, 'left', [.7 .5 .25 .2], 10);
		
	case 3,   % center 3-view on selected point
		% check that a 3-view is open
		if ~checkfields(rx, 'ui', 'interpLoc') | ~ishandle(rx.ui.interpLoc(1))
			error('Need to open an interpolated 3-view window.')
		end
		
		% convert string specifications for whichPoint into an integer 
		if ischar(whichPoint)
			switch lower(whichPoint)
				case 'ac', whichPoint = 1;
				case 'pc', whichPoint = 2;
				case 'midsag', whichPoint = 3;
				otherwise, error('Invalid value for whichPoint.')
			end
		end
		
		% check that the point was set -- NaN indicates not yet:
		if any( isnan(pts(:,whichPoint)) )
			myWarnDlg('Point not yet set!');
			return
		end
		
		% convert points from volume -> prescription coordinatespts =
		pts = round( vol2rx(rx, rx.acpcPoints) );
		
		% set the UI fields
		for i = 1:3
			set( rx.ui.interpLoc(i), 'String', num2str(pts(i,whichPoint)) );
		end
		
		% refresh the 3-view to recenter
		rxRefresh3View(rx);

	otherwise, error('Invalid display flag.')
end

return
