function [o] = mtrPathwayDatabase(varargin)
% Pathway database (PDB) class constructor
%
%
% Examples:
%
% See also:  mtrExportFibersFromMatrix, mtrResampleSISPathways,
% fiberToStr3
%
% Stanford VISTA Team - Sherbondy must have written this

if nargin == 0
%    o.pathways_header = [];
    o.pathways = mtrPathwayStruct();
    o.pathway_statistic_headers = [];
    o.pathwaysCoords = {};
    o.mm_scale = [];
    o.scene_dim = [];
    o.ACPC = [];
    o = class(o,'mtrPathwayDatabase');
else
    if( isa(varargin{1},'mtrPathwayDatabase') )
        o = varargin{1};
    else
        pathway_database_filename = varargin(1);
        % XXX must get file loading version in here
%        o.pathway_header = [];
        o.pathways = mtrPathwayStruct();
        o.pathwaysCoords = {};
        o.pathway_statistic_headers = [];
        o.mm_scale = [];
        o.scene_dim = [];
        o.ACPC = [];
        o = class(o,'mtrPathwayDatabase');
    end
end