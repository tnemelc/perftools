classdef kMeanStrgRoiAnalyzerTool < roiAnalyzerTool
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Access = protected)
        function obj = loadRoisMask(obj, ~)
                for k = 1 : length(obj.isKS)
                    isName = char(obj.isKS(k));
                    mask = loadmat(fullfile(obj.dataPath, 'strg', isName, 'strgMask.mat'));
                    obj.roisMaskMap = mapInsert(obj.roisMaskMap, isName, mask);
                end
        end%loadMyoMask(obj)
        %%
        function obj = loadRoiLabels(obj)
            for k = 1 : length(obj.isKS)
                isName = obj.isKS{k};
                root = xml2struct(fullfile(obj.dataPath, 'strg', ['roiInfo_' isName, '.xml']));
                for m = 1 : length(root.roisInfo.roi)
                       if iscell(root.roisInfo.roi)
                            curRoiInfo = root.roisInfo.roi{m};
                        else
                            curRoiInfo = root.roisInfo.roi;
                        end
                    roiLabels.(['roi_' num2str(m)]) = curRoiInfo.name.Text;
                end
                obj.roiLabelsMap = mapInsert(obj.roiLabelsMap, isName, roiLabels);
            end
        end
    end
end

