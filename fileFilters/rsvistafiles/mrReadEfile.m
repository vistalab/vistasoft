function hdr = mrReadEfile(EfileName)
% header = mrReadEfile(EfileName)
%
% Returns header info from Efile produced by G. Glover's auto-recon program.
% Output is structure having field names corresponding to Glover's parameters.
%
% Ress 9/01
% $Author: bob $
% $Date: 2008/02/14 19:50:01 $
% ras, 07/05: imported into mrVista 2.0.
% ras, 10/08: reads alignment points for each slice.
if notDefined('EfileName')
	EfileName = mrvSelectFile('r', {'E*.7' '*.*'}, 'Select an E file ...');
end

hdr = [];

fid = fopen(EfileName);
if fid == -1
	Alert(['Could not open file: ' EfileName])
	return
end

% initialize empty fields for alignment info
% * ras 10/08: after some empirical testing, I believe gw_point1 represents
% the upper left-hand corner of each slice in scanner space, gw_point2 
% represents the lower left-hand corner, and gw_point3 represents the
% uppper right-hand corner. In the output header structure, I will store
% each set of points as a 3xnSlices array. The rows are the L->R, P->A, and
% I->S position of each point, respectively; and the columns are different
% slices.
hdr.gw_point1 = [];
hdr.gw_point2 = [];
hdr.gw_point3 = [];

nLine = 0;
while 1
	line = fgetl(fid);
	if ~ischar(line), break, end
	ieq = findstr(line, '=');
	lhs = deblank(line(1:ieq-1));
	rhs = line(ieq+2:end);
	switch lhs
		case 'rev'
			% Revision
			hdr.rev = rhs;
		case 'date of scan'
			% Date
			hdr.date = rhs;
			% Make this more reasonable
			hdr.date=[hdr.date(1:6),hdr.date(8:end)];
		case 'time of scan'
			% Time
			hdr.time = rhs;
		case 'patient name'
			% Name
			hdr.name = rhs;
		case 'psd'
			% PSD
			hdr.psd = rhs;
		case 'coil'
			% Coil
			hdr.coil = rhs;
		case 'examnum/seriesnum'
			vals = explode('/', rhs);
			hdr.examNum = str2num(vals{1});
			hdr.seriesNum = str2num(vals{2});
		case 'series description'
			hdr.seriesDescription = rhs;
		case 'patient id'
			hdr.patientID = rhs;
		case 'exam description'
			hdr.examDescription = rhs;
		case 'series description'
			hdr.seriesDescription = rhs;
		case 'num echoes'
			hdr.nechos = getNumberFromString(rhs);
		case 'slquant'
			% Number of slices
			hdr.slquant = getNumberFromString(rhs);
		case 'num time frames'
			% Number of frames
			hdr.nframes = getNumberFromString(rhs);
		case {'numextra discards' 'nextra discards'}
			% Number of discarded shots
			hdr.nextra = getNumberFromString(rhs);
		case 'nshot'
			% Number of interleaves
			hdr.nshots = getNumberFromString(rhs);
		case 'FOV'
			% Field of view (mm)
			hdr.FOV = getNumberFromString(rhs);
		case 'slice thick'
			% Slice thickness (mm)
			hdr.sliceThickness = getNumberFromString(rhs);
		case 'skip'
			% Slice spacing (skip)
			hdr.skip = getNumberFromString(rhs);
		case 'TR'
			% Echo time, TR (ms)
			hdr.TR = getNumberFromString(rhs);
		case 'TE'
			% Repetition time, TE (ms)
			hdr.TE = getNumberFromString(rhs);
		case 'time/frame'
			% Acquisition time (ms)
			hdr.tAcq = getNumberFromString(rhs);
		case 'equiv matrix size'
			% Equivalent matrix size
			hdr.equivMatSize = getNumberFromString(rhs);
		case 'imgsize'
			% Image size
			hdr.imgsize = getNumberFromString(rhs);
		case 'pixel size'
			% Pixel size (mm)
			hdr.pixel = getNumberFromString(rhs);
		case 'freq'
			% Frequency (MHz)
			hdr.freq = getNumberFromString(rhs)/1.e6;
		case 'flip angle'
			% Flip Angle (deg)
			hdr.flipAngle = str2num(rhs);
		case 'R1, R2, TG (mps)'
			% Gains [R1, R2, TG]
			hdr.R1 = getNumberFromString(rhs, 1);
			hdr.R2 = getNumberFromString(rhs, 2);
			hdr.TG = getNumberFromString(rhs, 3);
		case 'BigEndian'
			hdr.BigEndian = str2num(rhs);
		case 'start_loc'
			hdr.start_loc = [sscanf(rhs, '%f %f %f', 3)]';
		case 'gw_point1'
			hdr.gw_point1(:,end+1) = sscanf(rhs, '%f %f %f', 3);
		case 'gw_point2'
			hdr.gw_point2(:,end+1) = sscanf(rhs, '%f %f %f', 3);
		case 'gw_point3'
			hdr.gw_point3(:,end+1) = sscanf(rhs, '%f %f %f', 3);			
		otherwise
			% try to record the remaining fields, if the descriptions are
			% valid field names
			try
				hdr.(lhs) = rhs;
			catch
				% oh well...
% 				fprintf('Missed: %s, %s\n', lhs, rhs);  % debug
			end
	end
end
