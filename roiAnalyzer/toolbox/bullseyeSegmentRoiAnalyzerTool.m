classdef bullseyeSegmentRoiAnalyzerTool < roiAnalyzerTool
    %myocardium roi analysis tool. processes myocardium roi
    %   and voxels features
    
    properties
    end
    
    methods (Access = protected)
        function obj = loadRoisMask(obj, ~)
                for k = 1 : length(obj.isKS)
                    isName = obj.isKS{k};
                    try 
                        mask = loadmat(fullfile(obj.dataPath, 'segmentation', 'AHA_Segments', isName, 'labeledImg.mat'));
                    catch
                        mask = 0;
                    end
                    obj.roisMaskMap = mapInsert(obj.roisMaskMap, isName, mask);
                end
        end%loadMyoMask(obj)
    end
end

