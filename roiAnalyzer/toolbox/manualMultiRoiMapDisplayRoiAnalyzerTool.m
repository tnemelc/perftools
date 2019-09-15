classdef manualMultiRoiMapDisplayRoiAnalyzerTool < roiAnalyzerTool
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Access = protected)
        function obj = loadRoisMask(obj, ~)
                for k = 1 : length(obj.isKS)
                    isName = char(obj.isKS(k));
                    mask = loadmat(fullfile(obj.dataPath, 'segmentation', 'ManualMultiRoiMapDisplay', ['labelsMask_' isName '.mat']));
                    obj.roisMaskMap = mapInsert(obj.roisMaskMap, isName, mask);
                end
        end%loadMyoMask(obj)
    end
end

