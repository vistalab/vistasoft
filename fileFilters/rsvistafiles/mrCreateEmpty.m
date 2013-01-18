function mr = mrCreateEmpty;
% Create an empty mr struct.
%
% mr = mrCreateEmpty;
%
% ras 07/05.
mr.data = [];
mr.name = '';
mr.path = '';
mr.hdr = [];
mr.info.scanner = '';
mr.info.subject = '';
mr.info.subjectSex = '';
mr.info.subjectAge = [];
mr.info.date = '';
mr.info.scanStart = [];
mr.info.examNum = [];
mr.info.protocol = '';
mr.info.coil = '';
mr.format = '';
mr.spaces = [];
mr.voxelSize = [];
mr.dims = [];
mr.extent = [];
mr.dimUnits = '';
mr.dataUnits = '';
mr.dataRange = [];
mr.phaseFlag = 0;  % by default, set to 1 otherwise
mr.params = [];
mr.comments = '';

return