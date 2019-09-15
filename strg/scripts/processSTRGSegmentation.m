% processSTRGSegmentation.m
% brief: 
%
%
% references:
%
%
% input:
% arg1: ...
% arg2: ... 
% output:
%
% arg3: ...
% arg4: ...
%
%
% keywords:
% author: C.Daviller
% date: 29-Jun-2018 


 function processSTRGSegmentation()
    clear variables;
    clc;
    rootPath = 'D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\clustering\';
    %% all patients with dense ischemic lesion
    densePatientSet = {
        '0001_ARGE', '0002_FACL', '0004_JUMI', ...
        '0006_THRO', '0007_OUGW', '0009_DEAL', ...
        '0012_RIAL', '0018_SALI', '0019_GRIR', ...
        '0021_CUCH', '0024_IBOU', '0027_CRCH', ...
        '0030_MARE', '0039_MOBE', '0045_TICH', ...
        '0049_POAI', '0050_BRFR', '0052_CLYV', ...
        '1001_BODA', '1002_NEMO', '1003_GAJE', ...
        '1004_GEMI'};
    %% all patients with diffuse perfusion defect
    diffusePatientSet = {
        '0003_CHAL', '0015_ROJE', '0022_HODO', ...
        '0029_HURO', '0040_SEJO', '0041_LUEL', ...
        '0042_BELA', '0048_BUJA'};
   %% all patient without perfusion defect
   normalPatientSet = {
       '0010_LEOD', '0014_INCA', '0026_SARE', ...
       '0028_DUCY', '0034_FAAN', '0035_PITH', ...
       '0037_DUHE'};
    % all patient with perfusion defect
    lesionPatientSet = {
        '0001_ARGE', '0002_FACL', '0003_CHAL', ...
        '0004_JUMI', '0005_COJE', '0006_THRO', ...
        '0007_OUGW', '0009_DEAL', '0012_RIAL', ...
        '0015_ROJE', '0018_SALI', '0019_GRIR', ...
        '0021_CUCH', '0022_HODO', '0024_IBOU', ...
        '0027_CRCH', '0029_HURO', '0030_MARE', ...
        '0039_MOBE', '0040_SEJO', '0041_LUEL', ...
        '0042_BELA', '0045_TICH', '0048_BUJA', ...
        '0049_POAI', '0050_BRFR', '0052_CLYV', ...
        '1001_BODA', '1002_NEMO', '1003_GAJE', ...
        '1004_GEMI'};
    
    %% test set
    testPatientSet = {'0000_Test'};

    %% processing
    patientSet = lesionPatientSet;
    
    cprintf('DGreen', 'init:\n');
    
    lgr = logger.getInstance();
    
    opt.dimKS = {'maxSlope', 'PeakVal', 'delay', 'TTP'};
        
    for k = 1 : length(patientSet)
        lgr.info(sprintf('patient: %s', patientSet{k}));
        
        opt.dataPath = fullfile(rootPath, patientSet{k});
        featTool = kMeanSTRGFeatTool();
        try
            lgr.info('running');
            featTool = featTool.prepare(opt);
            featTool = featTool.run();
        catch e
            lgr.err('something bad happened during run enter log.dumpTrace() ');
            rethrow(e);
        end
        lgr.info('save results');
        
        savePath = fullfile(opt.dataPath, 'strg');        
        emptyDir(savePath);
        isKS = featTool.getSliceKS();
        try
            for m = 1 : length(isKS)
                mkdir(fullfile(savePath, isKS{m}));
                kmeanMask = featTool.getKMeanLesionRoiMask(isKS{m});
                savemat(fullfile(savePath, isKS{m}, 'kMeanMask'), kmeanMask);
                nbRois = max(kmeanMask(:));
                strgMask = zeros(size(kmeanMask));
                root.roisInfo.strg_tolerance = featTool.getStrgTolerance();
                for n = 1 : nbRois
                    tmp = featTool.getStrgMask(isKS{m}, n);
                    strgMask(tmp > 0) = n;
                    root.roisInfo.roi{n}.id = n;
                    root.roisInfo.roi{n}.name = sprintf('lesion%d', n);
                    [x, y] = ind2sub(size(tmp), find(tmp == 1, 1, 'first'));
                    root.roisInfo.roi{n}.seed.x = x;
                    root.roisInfo.roi{n}.seed.y = y;
                    root.roisInfo.roi{n}.thresh = max(tmp(:));
                end
                savemat(fullfile(savePath, isKS{m}, 'strgMask'), strgMask);
                savemat(fullfile(savePath, isKS{m}, 'myoMask'), featTool.getMyoMask(isKS{m}));
                struct2xml(root, fullfile(savePath, ['roiInfo_' isKS{m} '.xml']));
                root = [];
            end
        catch e
            lgr.err('something bad happened during run enter log.dumpTrace() ');
            rethrow(e)
        end
    end
    
    lgr.info('processing completed!!!!');
end