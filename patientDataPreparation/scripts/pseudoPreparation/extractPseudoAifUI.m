% extractPseudoAifUI.m
% brief: 
% extractPseudoAif User Interface
% author: C.Daviller
% date: 03-Jul-2018 


function  extractPseudoAifUI()
    rootPath = 'D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\clustering\1004_GEMI';
    dataPath = fullfile(rootPath, 'base\tmp\02_images');
    savePath = fullfile(rootPath, 'dataPrep', 'Aif');
    
    
    
    [aif, tAcq, aifPeakPosition, PDScanNber, aifMask, thresh] = extractPseudoAif(dataPath);
    figure; plot(tAcq, aif);
    emptyDir(savePath);
    savemat(fullfile(savePath, 'aif.mat'), aif);
    savemat(fullfile(savePath, 'aifCtc.mat'), aif .* nan);
    savemat(fullfile(savePath, 'aifCtcFit.mat'), aif .* nan);
    
    savemat(fullfile(savePath, 'aifMask.mat'), aifMask);
    savemat(fullfile(savePath, 'tAcq.mat'), tAcq);
    
end