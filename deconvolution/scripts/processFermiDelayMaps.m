% processFermiDelayMaps.m
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
% date: 26-Nov-2018 


 function [arg3, arg4] = processFermiDelayMaps(arg1, arg2)
    lgr = logger.getInstance();
    rootPath = 'D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\3T\';
    patientSet =  {'0001_ARGE', '1001_BODA', '0003_CHAL', ...
         '0005_COCO', '0009_DEAL',  '0002_FACL',...
         '0004_JUMI', '1002_NEMO', '0007_OUGW',...
         '0012_RIAL', '0018_SALI', '0006_THRO'};
    
    slcKS = {'base', 'mid', 'apex'};
    
    for k = 1 : length(patientSet)
        curPatient =  patientSet{k};
        lgr.info(sprintf('patient: %s', patientSet{k}));
        roiToolOpt.dataPath = fullfile(rootPath, curPatient);
        roiTool = bullseyeSegmentRoiAnalyzerTool;
        roiTool = roiTool.prepare(roiToolOpt);
        roiTool = roiTool.run(roiToolOpt);
        
        
        for n = 1 : length(slcKS)
            delayMap = roiTool.getFeaturesMask('voxelTicDelay', slcKS{n});
            %delayMap(delayMap > 10) = 10;
            savemat(fullfile(rootPath, curPatient, 'deconvolution/Fermi/', slcKS{n}, 'delayMap.mat'), delayMap);
        end
    end
    
    
    

end