classdef expertSegSimilarityTool < segSimilarityTool
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        expert1MaskMap;
        expert2MaskMap;
    end
    
    methods (Access = public)
        %% 
        function obj = protected(obj, ~)
            obj.loadExpertSegmentations();
        end
        %%
        function obj = run(obj, ~)
            obj = obj.run@cPerfImSerieTool();
            obj = obj.loadMyoMask();
            obj = obj.loadSegmentationMasks();
            obj = obj.processMasksSimilarity();
            obj = obj.processInclusionCriterion();
        end
        
        
    end
    
    
    methods (Access = protected)
        function loadExpertSegmentations(obj)
            for k = 1 : length(obj.isKS)
                isName = obj.isKS{k};
                expert1LesionMask = loadmat(fullfile(obj.dataPath, 'segmentation', 'expert1', ['labelsMask_' isName '.mat']));
                expert2LesionMask = loadmat(fullfile(obj.dataPath, 'segmentation', 'expert2', ['labelsMask_' isName '.mat']));
                roiInfoStruct = xml2struct(fullfile(obj.dataPath, 'segmentation', 'ManualMultiRoiMapDisplay', ['roiInfo_' isName '.xml']));
                gndTrthMask = extractLesionLabels(obj, roiInfoStruct, gndTrthMask);
                
                
                kMeanSegMask = loadmat(fullfile(obj.dataPath, 'strg', isName, 'kMeanMask.mat'));
                strgSegMask  = loadmat(fullfile(obj.dataPath, 'strg', isName, 'strgMask.mat'));
                
                obj.groundTruthMaskMap = mapInsert(obj.groundTruthMaskMap, isName, gndTrthMask);
                obj.kMeanMaskMap = mapInsert(obj.kMeanMaskMap, isName, kMeanSegMask);
                obj.strgMaskMap =  mapInsert(obj.strgMaskMap, isName, strgSegMask);
            end
            
        end
    end
end

