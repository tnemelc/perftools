% processRoiMbfSimilarity.m
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
% date: 23-Jul-2018 


 function [arg3, arg4] = processRoiMbfVariability(arg1, arg2)
    clear variables;
    clc;
    rootPath = 'D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\clustering\';
    
     %% all patients with dense ischemic lesion
    densePatientSet = {
        '0001_ARGE', '0002_FACL', '0004_JUMI', ...
        '0006_THRO', '0007_OUGW', '0009_DEAL', ...
        '0012_RIAL', '0018_SALI', '0019_GRIR', ...
        '0021_CUCH', '0024_IBOU', '0027_CRCH', ...
        '0030_MARE', '0039_MOBE', ...
        '0049_POAI', '0050_BRFR', '0052_CLYV', ...
        '1001_BODA', '1002_NEMO'};
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
        '0042_BELA', '0048_BUJA', ...
        '0049_POAI', '0050_BRFR', '0052_CLYV', ...
        '1001_BODA', '1002_NEMO'};
    
    %% test set
    testPatientSet = {'0002_FACL'};
    
%     patientSet = diffusePatientSet;
    patientSet = lesionPatientSet;
%     patientSet = densePatientSet;
%     patientSet = testPatientSet;
       isKS = {'apex', 'mid', 'base'};

       
    similarityTool = segSimilarityTool();

    for k = 1 : length(patientSet)
        opt.dataPath = fullfile(rootPath, patientSet{k});
        similarityTool = similarityTool.prepare(opt);
        similarityTool = similarityTool.run();
        
        patientName = patientSet{k};
        patientName = patientName(6 : end);
        
        for m = 1 : length(isKS)
            gndTruthMask = similarityTool.getGndTruthMask(isKS{m});
            kMeanMask = similarityTool.getSegmentationMask(isKS{m}, 'kMean');
            strgMask = similarityTool.getSegmentationMask(isKS{m}, 'strg');
            ahaMask = similarityTool.getSegmentationMask(isKS{m}, 'ahaLesion');
            ahaNormalMask = similarityTool.getSegmentationMask(isKS{m}, 'ahaNormal');
            normalMask = similarityTool.getSegmentationMask(isKS{m}, 'manualNormal');

            
            mbfMaskBay =   loadmat(fullfile(rootPath, patientSet{k}, 'deconvolution', 'Bayesian', isKS{m}, 'mbfMap.mat'));
            mbfMaskFermi = loadmat(fullfile(rootPath, patientSet{k}, 'deconvolution', 'Fermi', isKS{m}, 'mbfMap.mat'));
            
            
            gndTruthMbfFermiVect = mbfMaskFermi(gndTruthMask >= 1);
            kMeanMbfFermiVect = mbfMaskFermi(kMeanMask >= 1);
            strgMbfFermiVect = mbfMaskFermi(strgMask >= 1);
            ahaMbfFermiVect = mbfMaskFermi(ahaMask >= 1);
            ahaNormalMbfFermiVect = mbfMaskFermi(ahaNormalMask >= 1);
            normalMbfFermiVect = mbfMaskFermi(normalMask >= 1);
            
            gndTruthMbfBayVect = mbfMaskBay(gndTruthMask >= 1);
            kMeanMbfBayVect = mbfMaskBay(kMeanMask >= 1);
            strgMbfBayVect = mbfMaskBay(strgMask >= 1);
            ahaMbfBayVect = mbfMaskBay(ahaMask >= 1);
            ahaNormalMbfBayVect = mbfMaskBay(ahaNormalMask >= 1);
            normalMbfBayVect = mbfMaskBay(normalMask >= 1);
            
            
            root.Bayesian.gndTruth.(isKS{m}).mean.(patientName) = mean(gndTruthMbfBayVect);
            root.Bayesian.gndTruth.(isKS{m}).std.(patientName) = std(gndTruthMbfBayVect);
            root.Fermi.gndTruth.(isKS{m}).mean.(patientName) = mean(gndTruthMbfFermiVect);
            root.Fermi.gndTruth.(isKS{m}).std.(patientName) = std(gndTruthMbfFermiVect);
            
            root.Bayesian.kMean.(isKS{m}).mean.(patientName) = mean(kMeanMbfBayVect);
            root.Bayesian.kMean.(isKS{m}).std.(patientName) = std(kMeanMbfBayVect);
            root.Fermi.kMean.(isKS{m}).mean.(patientName) = mean(kMeanMbfFermiVect);
            root.Fermi.kMean.(isKS{m}).std.(patientName) = std(kMeanMbfFermiVect);
            
            root.Bayesian.strg.(isKS{m}).mean.(patientName) = mean(strgMbfBayVect);
            root.Bayesian.strg.(isKS{m}).std.(patientName) = std(strgMbfBayVect);
            root.Fermi.strg.(isKS{m}).mean.(patientName) = mean(strgMbfFermiVect);
            root.Fermi.strg.(isKS{m}).std.(patientName) = std(strgMbfFermiVect);
            
            root.Bayesian.aha.(isKS{m}).mean.(patientName) = mean(ahaMbfBayVect);
            root.Bayesian.aha.(isKS{m}).std.(patientName) = std(ahaMbfBayVect);
            root.Fermi.aha.(isKS{m}).mean.(patientName) = mean(ahaMbfFermiVect);
            root.Fermi.aha.(isKS{m}).std.(patientName) = std(ahaMbfFermiVect);
            
            root.Bayesian.ahaNormal.(isKS{m}).mean.(patientName) = mean(ahaNormalMbfBayVect);
            root.Bayesian.ahaNormal.(isKS{m}).std.(patientName) = std(ahaNormalMbfBayVect);
            root.Fermi.ahaNormal.(isKS{m}).mean.(patientName) = mean(ahaNormalMbfFermiVect);
            root.Fermi.ahaNormal.(isKS{m}).std.(patientName) = std(ahaNormalMbfFermiVect);
            
            root.Bayesian.normal.(isKS{m}).mean.(patientName) = mean(normalMbfBayVect);
            root.Bayesian.normal.(isKS{m}).std.(patientName) = std(normalMbfBayVect);
            root.Fermi.normal.(isKS{m}).mean.(patientName) = mean(normalMbfFermiVect);
            root.Fermi.normal.(isKS{m}).std.(patientName) = std(normalMbfFermiVect);
            
        end
    end

    xml.root = root;
    struct2xml(xml, fullfile(rootPath, '0000_Results' , 'roiMbfVariability.xml'));
    system(sprintf('D:\\Programmes\\Notepad++\\notepad++.exe %s &', fullfile(rootPath, '0000_Results' , 'roiMbfVariability.xml')));
end