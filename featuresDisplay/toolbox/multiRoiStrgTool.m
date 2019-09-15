classdef multiRoiStrgTool < strg2Tool
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Access = protected)
        function obj = loadThresholdFeaturesMap(obj, opt)
            if nargin < 2
                opt.rootPath = fullfile(obj.patientPath, 'featuresDisplay');
            end
            emptyDir(fullfile(opt.rootPath))
            obj.processRoiAvgTicFeatures(opt);
            threshRoifeaturesTab = nan(obj.maxThreshold, length(obj.slcKS), length(obj.dimKS)); % threshRoifeaturesTab : obj.maxThreshold x user slected dims x nb imseries (slices)
            for k = 1 : length(obj.dimKS)
                for l = 1 : length(obj.slcKS)
                    try
                        threshRoifeaturesTab(:, l, k) = loadmat(fullfile(opt.rootPath, char(obj.slcKS(l)), char(obj.dimKS(k))));
                    catch e
                        disp(e);
                    end
                end
            end% for k..
            
            for k = 1 : length(obj.slcKS)
                obj.slcThreshRoiFeaturesTabMap = mapInsert(obj.slcThreshRoiFeaturesTabMap, char(obj.slcKS(k)), squeeze(threshRoifeaturesTab(:, k, :)));
            end
        end%loadThresholdFeaturesMap
    end%methods (Access = protected)
end

