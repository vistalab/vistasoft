rd = RdtClient('isetbio');
rd.openBrowser('fancy',true)


rd.crp('/');
rd.listRemotePaths('print',true);
a = rd.listArtifacts('print',true);
d = rd.readArtifact('afq');
afq = d.afq;

rd.crp('/AFQ');
a = rd.listArtifacts;
rd.readArtifact(a(2),'type','nii','downloadFolder',fullfile(vistaRootPath,'local'));

rd.crp('/vistadata/anatomy');
a = rd.listArtifacts;
d = rd.readArtifact('t1.nii');


%% Put some vista data files up on the site

% cd(vistadata)
rd = RdtClient('vistasoft');
rd.credentialsDialog;


a = rd.searchArtifacts('mrInit_params')

foo = struct2cell(a);
ID = foo(1,1,:); ID = squeeze(ID);
RemPath = foo(5,1,:);RemPath = squeeze(RemPath);
Type = foo(7,1,:);Type = squeeze(Type);
T = table(ID,Type,RemPath);

            % Search for remote artifacts by fuzzy text matching.
            %   artifacts = obj.searchArtifacts(text) match against text
            %   ( ... 'remotePath', remotePath) remotePath instead of pwrp()
            %   ( ... 'artifactId', artifactId) restrict to artifactId
            %   ( ... 'version', version) restrict to version
            %   ( ... 'type', type) restrict to type
            