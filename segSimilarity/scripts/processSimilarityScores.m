% processDice.m
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
% date: 27-Jun-2018


function processSimilarityScores(arg1, arg2)
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
    %% all patient with perfusion defect
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
    testPatientSet = {'0042_BELA'};
    
%    patientSet = lesionPatientSet;
%     patientSet = diffusePatientSet;
%      patientSet = densePatientSet;
    patientSet = testPatientSet;
    
    similarityTool = segSimilarityTool();
    kMeanCentroidVect.apex = [];
    kMeanCentroidVect.mid = [];
    kMeanCentroidVect.base = [];
    
    strgCentroidVect.apex = [];
    strgCentroidVect.mid = [];
    strgCentroidVect.base = [];
    
    for k = 1 : length(patientSet)
        logger.getInstance().info(patientSet{k});
        opt.dataPath = fullfile(rootPath, patientSet{k});
        similarityTool = similarityTool.prepare(opt);
        similarityTool = similarityTool.run();

        patientName = patientSet{k};
        patientName = patientName(6 : end);
        %% dice
                %%kmean
        root.dice.kmean.apex.(patientName) = similarityTool.getDiceCoeff('apex', 'kMean');
        root.dice.kmean.mid.(patientName) = similarityTool.getDiceCoeff('mid', 'kMean');
        root.dice.kmean.base.(patientName) = similarityTool.getDiceCoeff('base', 'kMean');
                %%strg
        root.dice.strg.apex.(patientName) = similarityTool.getDiceCoeff('apex', 'strg');
        root.dice.strg.mid.(patientName) = similarityTool.getDiceCoeff('mid', 'strg');
        root.dice.strg.base.(patientName) = similarityTool.getDiceCoeff('base', 'strg');
                %%kmean dice vector
        kMeanDiceVect.apex(k) = similarityTool.getDiceCoeff('apex', 'kMean');
        kMeanDiceVect.mid(k) = similarityTool.getDiceCoeff('mid', 'kMean');
        kMeanDiceVect.base(k) = similarityTool.getDiceCoeff('base', 'kMean');
                %%strg dice vector
        strgDiceVect.apex(k) = similarityTool.getDiceCoeff('apex', 'strg');
        strgDiceVect.mid(k)  = similarityTool.getDiceCoeff('mid', 'strg');
        strgDiceVect.base(k) = similarityTool.getDiceCoeff('base', 'strg');
        
        %% haussdorf distance
        root.hdd.kmean.apex.(patientName) = similarityTool.getHaussdorfDist('apex', 'kMean');
        root.hdd.kmean.mid.(patientName) = similarityTool.getHaussdorfDist('mid', 'kMean');
        root.hdd.kmean.base.(patientName) = similarityTool.getHaussdorfDist('base', 'kMean');
        %%strg
        root.hdd.strg.apex.(patientName) = similarityTool.getHaussdorfDist('apex', 'strg');
        root.hdd.strg.mid.(patientName) = similarityTool.getHaussdorfDist('mid', 'strg');
        root.hdd.strg.base.(patientName) = similarityTool.getHaussdorfDist('base', 'strg');
        %%kmean dice vector
        kMeanHddVect.apex(k) = similarityTool.getHaussdorfDist('apex', 'kMean');
        kMeanHddVect.mid(k) = similarityTool.getHaussdorfDist('mid', 'kMean');
        kMeanHddVect.base(k) = similarityTool.getHaussdorfDist('base', 'kMean');
        %%strg dice vector
        strgHddVect.apex(k) = similarityTool.getHaussdorfDist('apex', 'strg');
        strgHddVect.mid(k)  = similarityTool.getHaussdorfDist('mid', 'strg');
        strgHddVect.base(k) = similarityTool.getHaussdorfDist('base', 'strg');
        
        %% inclusion criterion
        root.inclusion.kmean.apex.(patientName) = similarityTool.getInclusionCoeff('apex', 'kMean');
        root.inclusion.kmean.mid.(patientName) = similarityTool.getInclusionCoeff('mid', 'kMean');
        root.inclusion.kmean.base.(patientName) = similarityTool.getInclusionCoeff('base', 'kMean');
        %%strg
        root.inclusion.strg.apex.(patientName) = similarityTool.getInclusionCoeff('apex', 'strg');
        root.inclusion.strg.mid.(patientName) = similarityTool.getInclusionCoeff('mid', 'strg');
        root.inclusion.strg.base.(patientName) = similarityTool.getInclusionCoeff('base', 'strg');
        %%kmean dice vector
        kMeanInclusionVect.apex(k) = similarityTool.getInclusionCoeff('apex', 'kMean');
        kMeanInclusionVect.mid(k) = similarityTool.getInclusionCoeff('mid', 'kMean');
        kMeanInclusionVect.base(k) = similarityTool.getInclusionCoeff('base', 'kMean');
        %%strg dice vector
        strgInclusionVect.apex(k) = similarityTool.getInclusionCoeff('apex', 'strg');
        strgInclusionVect.mid(k)  = similarityTool.getInclusionCoeff('mid', 'strg');
        strgInclusionVect.base(k) = similarityTool.getInclusionCoeff('base', 'strg');
        
        %% intersection criterion
        root.intersection.kmean.apex.(patientName) = similarityTool.getIntersectionCoeff('apex', 'kMean');
        root.intersection.kmean.mid.(patientName) = similarityTool.getIntersectionCoeff('mid', 'kMean');
        root.intersection.kmean.base.(patientName) = similarityTool.getIntersectionCoeff('base', 'kMean');
        %%strg
        root.intersection.strg.apex.(patientName) = similarityTool.getIntersectionCoeff('apex', 'strg');
        root.intersection.strg.mid.(patientName) = similarityTool.getIntersectionCoeff('mid', 'strg');
        root.intersection.strg.base.(patientName) = similarityTool.getIntersectionCoeff('base', 'strg');
        %%kmean intersection vector
        kMeanIntersectionVect.apex(k) = similarityTool.getIntersectionCoeff('apex', 'kMean');
        kMeanIntersectionVect.mid(k) = similarityTool.getIntersectionCoeff('mid', 'kMean');
        kMeanIntersectionVect.base(k) = similarityTool.getIntersectionCoeff('base', 'kMean');
        %%strg intersection vector
        strgIntersectionVect.apex(k) = similarityTool.getIntersectionCoeff('apex', 'strg');
        strgIntersectionVect.mid(k)  = similarityTool.getIntersectionCoeff('mid', 'strg');
        strgIntersectionVect.base(k) = similarityTool.getIntersectionCoeff('base', 'strg');
        
        %% Jaccard index
        root.jaccard.kmean.apex.(patientName) = similarityTool.getJaccardCoeff('apex', 'kMean');
        root.jaccard.kmean.mid.(patientName) = similarityTool.getJaccardCoeff('mid', 'kMean');
        root.jaccard.kmean.base.(patientName) = similarityTool.getJaccardCoeff('base', 'kMean');
        %%strg
        root.jaccard.strg.apex.(patientName) = similarityTool.getJaccardCoeff('apex', 'strg');
        root.jaccard.strg.mid.(patientName) = similarityTool.getJaccardCoeff('mid', 'strg');
        root.jaccard.strg.base.(patientName) = similarityTool.getJaccardCoeff('base', 'strg');
        %%kmean dice vector
        kMeanJaccardVect.apex(k) = similarityTool.getJaccardCoeff('apex', 'kMean');
        kMeanJaccardVect.mid(k) = similarityTool.getJaccardCoeff('mid', 'kMean');
        kMeanJaccardVect.base(k) = similarityTool.getJaccardCoeff('base', 'kMean');
        %%strg jaccard vector
        strgJaccardVect.apex(k) = similarityTool.getJaccardCoeff('apex', 'strg');
        strgJaccardVect.mid(k)  = similarityTool.getJaccardCoeff('mid', 'strg');
        strgJaccardVect.base(k) = similarityTool.getJaccardCoeff('base', 'strg');
        
        %% Centroid distance
        root.centroid.kmean.apex.(patientName) = similarityTool.getCentroid('apex', 'kMean');
        root.centroid.kmean.mid.(patientName) = similarityTool.getCentroid('mid', 'kMean');
        root.centroid.kmean.base.(patientName) = similarityTool.getCentroid('base', 'kMean');
        %%strg
        root.centroid.strg.apex.(patientName) = similarityTool.getCentroid('apex', 'strg');
        root.centroid.strg.mid.(patientName) = similarityTool.getCentroid('mid', 'strg');
        root.centroid.strg.base.(patientName) = similarityTool.getCentroid('base', 'strg');
        %%kmean dice vector
        kMeanCentroidVect.apex = [ kMeanCentroidVect.apex similarityTool.getCentroid('apex', 'kMean') ];
        kMeanCentroidVect.mid =  [ kMeanCentroidVect.mid  similarityTool.getCentroid('mid', 'kMean') ];
        kMeanCentroidVect.base = [ kMeanCentroidVect.base similarityTool.getCentroid('base', 'kMean') ];
        %%strg centroid vector
        strgCentroidVect.apex = [ strgCentroidVect.apex similarityTool.getCentroid('apex', 'strg')];
        strgCentroidVect.mid  = [ strgCentroidVect.mid  similarityTool.getCentroid('mid', 'strg') ];
        strgCentroidVect.base = [ strgCentroidVect.base similarityTool.getCentroid('base', 'strg')];
        
    end
    
    seriesSet = {'base', 'mid', 'apex'};
    
    for k = 1 : length(seriesSet)
        %% dice
        root.dice.kmean.(seriesSet{k}).mean  = mean(kMeanDiceVect.(seriesSet{k}));
        root.dice.kmean.(seriesSet{k}).medi  = median(kMeanDiceVect.(seriesSet{k}));
        root.dice.kmean.(seriesSet{k}).std_  = std(kMeanDiceVect.(seriesSet{k}));
        root.dice.kmean.(seriesSet{k}).min_  = min(kMeanDiceVect.(seriesSet{k}));
        root.dice.kmean.(seriesSet{k}).max_  = max(kMeanDiceVect.(seriesSet{k}));
        
        root.dice.strg.(seriesSet{k}).mean   = mean(strgDiceVect.(seriesSet{k}));
        root.dice.strg.(seriesSet{k}).medi   = median(strgDiceVect.(seriesSet{k}));
        root.dice.strg.(seriesSet{k}).std_   = std(strgDiceVect.(seriesSet{k}));
        root.dice.strg.(seriesSet{k}).min_   = min(strgDiceVect.(seriesSet{k}));
        root.dice.strg.(seriesSet{k}).max_   = max(strgDiceVect.(seriesSet{k}));
        
        %% hdaussdorf distance
        root.hdd.kmean.(seriesSet{k}).mean   = mean(kMeanHddVect.(seriesSet{k}));
        root.hdd.kmean.(seriesSet{k}).medi   = median(kMeanHddVect.(seriesSet{k}));
        root.hdd.kmean.(seriesSet{k}).std_   = std(kMeanHddVect.(seriesSet{k}));
        root.hdd.kmean.(seriesSet{k}).min_   = min(kMeanHddVect.(seriesSet{k}));
        root.hdd.kmean.(seriesSet{k}).max_   = max(kMeanHddVect.(seriesSet{k}));
        
        root.hdd.strg.(seriesSet{k}).mean    = mean(strgHddVect.(seriesSet{k}));
        root.hdd.strg.(seriesSet{k}).medi    = median(strgHddVect.(seriesSet{k}));
        root.hdd.strg.(seriesSet{k}).std_    = std(strgHddVect.(seriesSet{k}));
        root.hdd.strg.(seriesSet{k}).min_    = min(strgHddVect.(seriesSet{k}));
        root.hdd.strg.(seriesSet{k}).max_    = max(strgHddVect.(seriesSet{k}));
        
        %% inclusion criterion
        root.inclusion.kmean.(seriesSet{k}).mean   = mean(kMeanInclusionVect.(seriesSet{k}));
        root.inclusion.kmean.(seriesSet{k}).medi   = median(kMeanInclusionVect.(seriesSet{k}));
        root.inclusion.kmean.(seriesSet{k}).std_   = std(kMeanInclusionVect.(seriesSet{k}));
        root.inclusion.kmean.(seriesSet{k}).min_   = min(kMeanInclusionVect.(seriesSet{k}));
        root.inclusion.kmean.(seriesSet{k}).max_   = max(kMeanInclusionVect.(seriesSet{k}));
        
        root.inclusion.strg.(seriesSet{k}).mean    = mean(strgInclusionVect.(seriesSet{k}));
        root.inclusion.strg.(seriesSet{k}).medi    = median(strgInclusionVect.(seriesSet{k}));
        root.inclusion.strg.(seriesSet{k}).std_    = std(strgInclusionVect.(seriesSet{k}));
        root.inclusion.strg.(seriesSet{k}).min_    = min(strgInclusionVect.(seriesSet{k}));
        root.inclusion.strg.(seriesSet{k}).max_    = max(strgInclusionVect.(seriesSet{k}));
        
        %% intersection criterion
        root.intersection.kmean.(seriesSet{k}).mean   = mean(kMeanIntersectionVect.(seriesSet{k}));
        root.intersection.kmean.(seriesSet{k}).medi   = median(kMeanIntersectionVect.(seriesSet{k}));
        root.intersection.kmean.(seriesSet{k}).std_   = std(kMeanIntersectionVect.(seriesSet{k}));
        root.intersection.kmean.(seriesSet{k}).min_   = min(kMeanIntersectionVect.(seriesSet{k}));
        root.intersection.kmean.(seriesSet{k}).max_   = max(kMeanIntersectionVect.(seriesSet{k}));
        
        root.intersection.strg.(seriesSet{k}).mean    = mean(strgIntersectionVect.(seriesSet{k}));
        root.intersection.strg.(seriesSet{k}).medi    = median(strgIntersectionVect.(seriesSet{k}));
        root.intersection.strg.(seriesSet{k}).std_    = std(strgIntersectionVect.(seriesSet{k}));
        root.intersection.strg.(seriesSet{k}).min_    = min(strgIntersectionVect.(seriesSet{k}));
        root.intersection.strg.(seriesSet{k}).max_    = max(strgIntersectionVect.(seriesSet{k}));
        
        %% Jaccard criterion
        root.jaccard.kmean.(seriesSet{k}).mean   = mean(kMeanJaccardVect.(seriesSet{k}));
        root.jaccard.kmean.(seriesSet{k}).medi   = median(kMeanJaccardVect.(seriesSet{k}));
        root.jaccard.kmean.(seriesSet{k}).std_   = std(kMeanJaccardVect.(seriesSet{k}));
        root.jaccard.kmean.(seriesSet{k}).min_   = min(kMeanJaccardVect.(seriesSet{k}));
        root.jaccard.kmean.(seriesSet{k}).max_   = max(kMeanJaccardVect.(seriesSet{k}));
        
        root.jaccard.strg.(seriesSet{k}).mean    = mean(strgJaccardVect.(seriesSet{k}));
        root.jaccard.strg.(seriesSet{k}).medi    = median(strgJaccardVect.(seriesSet{k}));
        root.jaccard.strg.(seriesSet{k}).std_    = std(strgJaccardVect.(seriesSet{k}));
        root.jaccard.strg.(seriesSet{k}).min_    = min(strgJaccardVect.(seriesSet{k}));
        root.jaccard.strg.(seriesSet{k}).max_    = max(strgJaccardVect.(seriesSet{k}));
        
        %% Centroid dist
        root.centroid.kmean.(seriesSet{k}).mean   = mean(kMeanCentroidVect.(seriesSet{k}));
        root.centroid.kmean.(seriesSet{k}).medi   = median(kMeanCentroidVect.(seriesSet{k}));
        root.centroid.kmean.(seriesSet{k}).std_   = std(kMeanCentroidVect.(seriesSet{k}));
        root.centroid.kmean.(seriesSet{k}).min_   = min(kMeanCentroidVect.(seriesSet{k}));
        root.centroid.kmean.(seriesSet{k}).max_   = max(kMeanCentroidVect.(seriesSet{k}));
        
        root.centroid.strg.(seriesSet{k}).mean    = mean(strgCentroidVect.(seriesSet{k}));
        root.centroid.strg.(seriesSet{k}).medi    = median(strgCentroidVect.(seriesSet{k}));
        root.centroid.strg.(seriesSet{k}).std_    = std(strgCentroidVect.(seriesSet{k}));
        root.centroid.strg.(seriesSet{k}).min_    = min(strgCentroidVect.(seriesSet{k}));
        root.centroid.strg.(seriesSet{k}).max_    = max(strgCentroidVect.(seriesSet{k}));
        
    end
    xml.root = root;
    struct2xml(xml, fullfile(rootPath, '0000_Results' , 'segSimilarity.xml'));
    system(sprintf('D:\\Programmes\\Notepad++\\notepad++.exe %s &', fullfile(rootPath, '0000_Results' , 'segSimilarity.xml')));
end