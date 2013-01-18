function [su_hdr,ex_hdr,se_hdr,im_hdr,pix_hdr,im_offset] = DICOM_readHeader(IFileName)
%
% [su_hdr,ex_hdr,se_hdr,im_hdr,pix_hdr,im_offset] = DICOM_readHeader(IFileName)
% Reads the header info from a DICOM file
% This basically calls the dicomread function, however we convert outputs
% into same as that of GE_readHeader.
%
% For further descript of DICOM, refer to manuals from nema.org
%
% If this code reports an error because of a non-existent field, please add
% the code of "if isfield(), end; " for protection.
%
% Junjie Liu 2004/01/23
% 2004.06.03 RFD: added scanspacing (slice gap, in mm).
% 2005.06.30 RFD: added double cast to dfov calculation to avoid int16 math
% in Matlab 7. This was wrecking havoc since ML7 was silently clipping
% values >32767, giving bogus dfov values. And, since the dfov is used to
% calculate the image coordinates in scanner-space, it was really screwing
% up all the code that relies on the scanner coords of the image.
% 2006.05.22 RFD: Disabled the fixMatlabBug attempt. It is makes things
% worse for current versions of matlab (>=7.1)

%try
    info = dicominfo(IFileName);
% catch
%     DICOM_fixMatlabBug;
%     info = dicominfo(IFileName);
% end
if(isfield(info,'StartOfPixelData'))
    im_offset = info.StartOfPixelData;
else
    im_offset = 0;
end

% Suite Header
su_hdr.su_id = double(info.StationName)';
if ~isfield(info,'ManufacturersModelName'); % protection for sometimes field not existent in old version. same below.
    info.ManufacturersModelName = 'Unknown';
end
su_hdr.prodid = double(info.ManufacturersModelName)';

% Exam Header
ex_hdr.ex_no = info.StudyID;
ex_hdr.hospname = double(info.InstitutionName)';

if ~checkfields(info, 'magstrength'),
    info.MagneticFieldStrength = 0;
end
ex_hdr.magstrength = info.MagneticFieldStrength*10000;%gauss
ex_hdr.patid = double(info.PatientID)';
if isfield(info,'AdditionalPatientHistory')
    ex_hdr.hist = double(info.AdditionalPatientHistory)';
else
    ex_hdr.hist = [];
end
ex_hdr.ex_datetime = str2num([info.StudyDate,info.StudyTime]);
% the old version used .Patientsxxx, such as .PatientsAge .PatientsSex etc., the new version used .Patientxxx, such as
% .PatientSex. We have to adapt to both versions.
if isfield(info,'PatientsSex')
    ex_hdr.patname = double(info.PatientsName.FamilyName)';
    if(isfield(info,'PatientsAge'))
        ex_hdr.patage = str2num(info.PatientsAge(1:end-1));
        ex_hdr.patian = ~strcmp(info.PatientsAge(end),'Y');
    else
        ex_hdr.patage = (datenum(info.StudyDate,'yyyymmdd')-datenum(info.PatientsBirthDate,'yyyymmdd'))./365.242199;
    end
    ex_hdr.patsex = strcmp(info.PatientsSex,'M');
    ex_hdr.patweight = info.PatientsWeight*1000;% gram
elseif isfield(info,'PatientSex')
    ex_hdr.patname = double(info.PatientName.FamilyName)';
    if(isfield(info,'PatientsAge'))
        ex_hdr.patage = str2num(info.PatientAge(1:end-1));
        ex_hdr.patian = ~strcmp(info.PatientAge(end),'Y');
    else
        ex_hdr.patage = (datenum(info.StudyDate,'yyyymmdd')-datenum(info.PatientBirthDate,'yyyymmdd'))./365.242199;
    end        
    ex_hdr.patsex = strcmp(info.PatientSex,'M');
    if ~checkfields(info, 'PatientWeight'),
        info.PatientWeight = 100 / 2.25; % kg?
    end
    ex_hdr.patweight = info.PatientWeight*1000;% gram
end    

if ~isfield(info,'AdditionalPatientHistory');
    info.AdditionalPatientHistory = 'Unknown';
end
%ex_hdr.refphy = double(info.ReferringPhysiciansName.FamilyName)';
if(~isfield(info, 'OperatorsName'))
    info.OperatorsName.FamilyName = '';
end
ex_hdr.op = double(info.OperatorsName.FamilyName)';
if(~isfield(info, 'StudyDescription'))
    ex_hdr.ex_desc = [];
else
    ex_hdr.ex_desc = double(info.StudyDescription)';
end
if ~isfield(info,'Modality');
    info.Modality = 'NA';
end
ex_hdr.ex_typ = double(info.Modality)';

% Series Header
se_hdr.se_exno = info.StudyID;
se_hdr.se_no = info.SeriesNumber;
se_hdr.se_datetime = str2num([info.SeriesDate,info.SeriesTime]);
se_hdr.se_desc = info.SeriesDescription;
if ~isfield(info,'ProtocolName');
    info.ProtocolName = 'Unknown';
end
se_hdr.prtcl = info.ProtocolName;
% In DICOM format, there seems to be no description of the start and end of
% series. Hence, I make them equal here, as a single DICOM-format image.
% If smart you can later find a field representing series start and end,
% please put it here.
if(isfield(info,'SliceLocation'))
    se_hdr.start_loc = info.SliceLocation;
else
    se_hdr.start_loc = info.ImagePositionPatient;
end
se_hdr.end_loc = se_hdr.start_loc;


% Image Header
im_hdr.im_exno = info.StudyID;
im_hdr.im_seno = info.SeriesNumber;
im_hdr.im_no = info.InstanceNumber;
% Another bug here, new vs. old version
if isfield(info,'ImageDate');
    im_hdr.im_datetime = str2num([info.ImageDate,info.ImageTime]);
else
    im_hdr.im_datetime = str2num([info.AcquisitionDate,info.AcquisitionTime]);
end
im_hdr.im_actual_dt = im_hdr.im_datetime;
im_hdr.slthick = info.SliceThickness;
if ~isfield (info, 'SpacingBetweenSlices')
    im_hdr.scanspacing = 0;
else
    im_hdr.scanspacing = info.SpacingBetweenSlices-info.SliceThickness;
end;

im_hdr.imatrix_X = info.Columns; % X is row direction, so count columns.
im_hdr.imatrix_Y = info.Rows;
im_hdr.pixsize_X = info.PixelSpacing(1);
im_hdr.pixsize_Y = info.PixelSpacing(2);
% 2005.06.30 RFD: cast as double to avoid int16 math in Matlab 7. This was
% wrecking havoc since ML7 was silently clipping values >32767.
im_hdr.dfov = round(double(im_hdr.pixsize_X)*double(im_hdr.imatrix_X)*1000)/1000; % *1000/1000 allow for more accuracy
im_hdr.dfov_rect = round(double(im_hdr.pixsize_Y)*double(im_hdr.imatrix_Y)*1000)/1000;
im_hdr.dim_X = info.Width;
im_hdr.dim_Y = info.Height;
im_hdr.psd_iname = double(info.ScanOptions)';%not the real psd
if ~checkfields(info, 'RepetitionTime')
    info.RepetitionTime = 1000;
    %warning('Missing field: info.RepetitionTime. Using default value of 1000 ms.');
end
im_hdr.tr = info.RepetitionTime;
if ~isfield(info,'InversionTime');
    info.InversionTime = NaN;
end
im_hdr.ti = info.InversionTime;
if ~isfield(info,'EchoTime');
        info.EchoTime = NaN;
end
im_hdr.te = info.EchoTime;
if isfield(info,'EchoNumbers');% Yet another version problem, sigh...
    info.EchoNumber = info.EchoNumbers;
end    
if ~isfield(info, 'EchoNumber')
    info.EchoNumber = NaN;
end
im_hdr.numecho = info.EchoNumber;

if isfield(info,'NumberOfAverages');
    im_hdr.nex = info.NumberOfAverages;
else
    im_hdr.nex = 1;
end
if ~isfield(info,'HeartRate');
    im_hdr.hrtrate = 0;
else
    im_hdr.hrtrate = info.HeartRate;
end
im_hdr.sarpeak = NaN;
if(~isfield(info,'SAR'))
    im_hdr.saravg = NaN;
else
    im_hdr.saravg = info.SAR;
end
if ~isfield(info,'TriggerWindow');
    im_hdr.trgwindow = NaN;
else
    im_hdr.trgwindow = info.TriggerWindow;
end
if ~isfield(info,'CardiacNumberOfImages');
    im_hdr.imgpcyc = 0;
else
    im_hdr.imgpcyc = info.CardiacNumberOfImages;
end
if ~isfield(info, 'FlipAngle')
    info.FlipAngle = NaN;
end
im_hdr.mr_flip = info.FlipAngle;

if ~isfield(info, 'ImagingFrequency')
    info.ImagingFrequency = NaN;
end
im_hdr.xmtfreq = info.ImagingFrequency*10000000; %(0.1Hz)
if isfield(info,'ReceivingCoil');
    im_hdr.cname = double(info.ReceivingCoil)';
elseif isfield(info,'ReceiveCoilName');
    im_hdr.cname = info.ReceiveCoilName;
end

im_hdr.sctime = [info.AcquisitionDate info.AcquisitionTime];

%DICOM format is in LPS coordinates (Left, Posterior, Superior), while GE
%signa format is in RAS coordinates. The top left corner of image is
%presented in DICOM format.
im_hdr.tlhc_R = -info.ImagePositionPatient(1);
im_hdr.tlhc_A = -info.ImagePositionPatient(2);
im_hdr.tlhc_S =  info.ImagePositionPatient(3);
%Now, top right corner is calculated from image size, row direction
im_hdr.trhc_R = im_hdr.tlhc_R - im_hdr.dfov * info.ImageOrientationPatient(1);
im_hdr.trhc_A = im_hdr.tlhc_A - im_hdr.dfov * info.ImageOrientationPatient(2);
im_hdr.trhc_S = im_hdr.tlhc_S + im_hdr.dfov * info.ImageOrientationPatient(3);
%and bottom right corner is calculated from image size, column direction
im_hdr.brhc_R = im_hdr.trhc_R - im_hdr.dfov_rect * info.ImageOrientationPatient(4);
im_hdr.brhc_A = im_hdr.trhc_A - im_hdr.dfov_rect * info.ImageOrientationPatient(5);
im_hdr.brhc_S = im_hdr.trhc_S + im_hdr.dfov_rect * info.ImageOrientationPatient(6);
im_hdr.ctr_R = (im_hdr.tlhc_R + im_hdr.brhc_R)/2;
im_hdr.ctr_A = (im_hdr.tlhc_A + im_hdr.brhc_A)/2;
im_hdr.ctr_S = (im_hdr.tlhc_S + im_hdr.brhc_S)/2;
%normal vector, perpendicular to image, but can be bi-directional.
norm_vec = cross(double([im_hdr.tlhc_R-im_hdr.trhc_R, im_hdr.tlhc_A-im_hdr.trhc_A, ...
        im_hdr.tlhc_S-im_hdr.trhc_S]),double([im_hdr.brhc_R-im_hdr.trhc_R, ...
        im_hdr.brhc_A-im_hdr.trhc_A, im_hdr.brhc_S-im_hdr.trhc_S]));
norm_vec = norm_vec/norm(norm_vec);
%by convention, the main direction of norm vector needs to be positive in GE signa format.
[junk whichmax] = max(abs(norm_vec));
if norm_vec(whichmax) < 0;
   norm_vec = -norm_vec;
end
im_hdr.norm_R = norm_vec(1); im_hdr.norm_A = norm_vec(2); im_hdr.norm_S = norm_vec(3);
eval('im_hdr.slquant = info.Private_0021_104f(1);','im_hdr.slquant = NaN;');

% Pixel Header
pix_hdr.img_width = info.Width;
pix_hdr.img_height = info.Height;
pix_hdr.img_depth = info.BitDepth;

return

for(ii=1:length(f))
    if(strmatch('Private', f{ii}))
        disp(['info.' f{ii}]);
        d = getfield(info, f{ii})';
        if(length(d)<256)
            disp(d);
        else
            disp('data > 256');
        end
    end
end

% % The following are some example outputs of GE_readheader and DICOM_readheader
% Case 1: Coronal Slices #1
%         R      A      S
% trhc: -110 -54.0296  110
% tlhc:  110 -54.0296  110
% brhc: -110 -54.0296 -110
% norm:   0      1      0
% se: start -54.0296 end -111.0296
% (slice thickness 3)
% info.ImagePositionPatient    = -110 54.0296 110
% info.ImageOrientationPatient = [1 0 0 0 0 -1]
% info.SliceLocation = -54.0296
% 
% Case 2: Sagittal Slices #2
%         R      A      S
% trhc: -75.9  -120   118.6
% tlhc: -75.9   120   118.6
% brhc: -75.9  -120  -121.4
% norm:   1      0      0
% se: start -77.1 end 70.5
% (slice thickness 1.2)
% info.ImagePositionPatient    = 75.9 -120 118.6
% info.ImageOrientationPatient = [0 1 0 0 0 -1] % (0020,0037)
% info.SliceLocation = -75.9
% 
% Case 3: Oblique Slices #3
%         R      A       S
% trhc: -110 117.5915 -20.1144
% tlhc:  110 117.5915 -20.1144
% brhc: -110 -76.4721  83.5240
% norm:   0    0.4711   0.8821
% se: start 36.9973 end -13.2819
% (slice thickness 3)
% info.ImagePositionPatient    = -110 -117.591 -20.1144
% info.ImageOrientationPatient = [1 0 0 0 0.8821 0.4711]
% info.SliceLocation = 31.7048
