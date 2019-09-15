% checkKmeansSegmentationRobustness.m
% brief: check kmeans lesion mask similarity. Runs segmentation N times over same patient, and
% measures dice similarity between detected kmeans lesion masks
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
% date: 14-Nov-2018 


 function [arg3, arg4] = checkKmeansSegmentationRobustness(arg1, arg2)
    clear variables;
    clc;
    rootPath = 'D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\clustering\';
    
    %% nb of iterations to play over each patient
    nbIt = 10;
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
    testPatientSet = {'0001_ARGE', '0003_CHAL'};

    %% slice keyset
    sliceKS = {'base', 'mid', 'apex'};
    %% processing
    patientSet = lesionPatientSet;
    
    lgr = logger.getInstance();
    
    opt.dimKS = {'maxSlope', 'PeakVal', 'delay', 'TTP'};
    
    for k = 1 : length(patientSet)
        
        
        
        for n = 1 : nbIt
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
            
            if n == 1
                [H, W] = size(featTool.getKMeanLesionRoiMask('base'));
                baseKMMaskStack = zeros(H, W, nbIt);
                midKMMaskStack = zeros(H, W, nbIt);
                apexKMMaskStack = zeros(H, W, nbIt);
                
                baseSTRGMaskStack = zeros(H, W, nbIt);
                midSTRGMaskStack = zeros(H, W, nbIt);
                apexSTRGMaskStack = zeros(H, W, nbIt);
            end
            
            
            
            baseKMMaskStack(:, :, n) = featTool.getKMeanLesionRoiMask('base');
            midKMMaskStack(:, :, n) = featTool.getKMeanLesionRoiMask('mid');
            apexKMMaskStack(:, :, n) = featTool.getKMeanLesionRoiMask('apex');
            
            baseSTRGMaskStack(:, :, n) = featTool.getStrgMask('base');
            midSTRGMaskStack(:, :, n) = featTool.getStrgMask('mid');
            apexSTRGMaskStack(:, :, n) = featTool.getStrgMask('apex');
        end%nbIt
        
        
        
        baseKMMaskStack(baseKMMaskStack > 1) = 1;
        midKMMaskStack(midKMMaskStack > 1) = 1;
        apexKMMaskStack(apexKMMaskStack > 1) = 1;
        
        KMDice.base = zeros(1, nbIt);
        KMDice.mid = zeros(1, nbIt);
        KMDice.apex = zeros(1, nbIt);
        
        STRGDice.base = zeros(1, nbIt);
        STRGDice.mid = zeros(1, nbIt);
        STRGDice.apex = zeros(1, nbIt);
        
        
        %measure dice between masks
        for n = 1 : nbIt
            KMDice.base(n) = dice(baseKMMaskStack(:, :, 1), baseKMMaskStack(:, :, n));
            KMDice.mid(n) =  dice(midKMMaskStack(:, :, 1), midKMMaskStack(:, :, n));
            KMDice.apex(n) = dice(apexKMMaskStack(:, :, 1), apexKMMaskStack(:, :, n));
            
            STRGDice.base(n) = dice(baseSTRGMaskStack(:, :, 1), baseSTRGMaskStack(:, :, n));
            STRGDice.mid(n) = dice(midSTRGMaskStack(:, :, 1), midSTRGMaskStack(:, :, n));
            STRGDice.apex(n) = dice(apexSTRGMaskStack(:, :, 1), apexSTRGMaskStack(:, :, n));
        end%for n = 2 : nbIt
        
%         lgr.info(sprintf('base Dice score (avg/min/max): %0.2f/%0.2f/%0.2f', mean(baseKMDice), min(baseKMDice), max(baseKMDice)));
%         lgr.info(sprintf('base Dice score (avg/min/max): %0.2f/%0.2f/%0.2f', mean(midKMDice), min(midKMDice), max(midKMDice)));
%         lgr.info(sprintf('base Dice score (avg/min/max): %0.2f/%0.2f/%0.2f', mean(apexKMDice), min(apexKMDice), max(apexKMDice)));

    
    curPat = patientSet{k}; curPat = curPat(6 : end);
    
    for m = 1 : length(sliceKS)
        curSlice = sliceKS{m};
        patients.(curPat).KMeans.(curSlice).mean = mean(KMDice.(curSlice)(:));
        patients.(curPat).KMeans.(curSlice).std = std(KMDice.(curSlice)(:));
        patients.(curPat).KMeans.(curSlice).max = max(KMDice.(curSlice)(:));
        patients.(curPat).KMeans.(curSlice).min = min(KMDice.(curSlice)(:));
        
        patients.(curPat).STRG.(curSlice).mean = mean(STRGDice.(curSlice)(:));
        patients.(curPat).STRG.(curSlice).std = std(STRGDice.(curSlice)(:));
        patients.(curPat).STRG.(curSlice).max = max(STRGDice.(curSlice)(:));
        patients.(curPat).STRG.(curSlice).min = min(STRGDice.(curSlice)(:));
    end
        
    end%for k = 1 : length(patientSet)
    
    root.patients = patients;
    struct2xml(root, fullfile(rootPath, '0000_Results', 'STRGRobustness.xml'));

end