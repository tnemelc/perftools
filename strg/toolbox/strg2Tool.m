classdef strg2Tool < thresholdFeatProcessingTool
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ftVariationTol; %features variation tolerance
    end
    
    methods (Access = public)
        %%
        function obj = prepare(obj, opt)
            obj = obj.prepare@thresholdFeatProcessingTool(opt);
            obj.ftVariationTol = 0.4;
        end
        %% getters
        %%
        function tol = getVariationTolerance(obj)
            tol = obj.ftVariationTol;
        end
    end%methods (Access = public)
    
    methods (Access = protected)
        %%
        function obj = processOptimalThresholdVals(obj)
            for k = 1 : length(obj.slcKS)
                ftTab = obj.slcThreshRoiFeaturesTabMap(obj.slcKS{k});
                %calculate seed tic feature vect distance from space origin
                % the reference distance.
                refDistance = norm(ftTab(4, :));
                % calculate features points distances
                % from reference point(seed )
                for m = 4 : size(ftTab)
                    ftPtDistVect(m) = norm(ftTab(m, :) - ftTab(4, :)) / refDistance;
                end
                %search last value lower than tolerance
                optThreshold = 3 + find(ftPtDistVect(:) < obj.ftVariationTol, 1, 'last');
                if isempty(optThreshold)
                    optThreshold = 1;
                end
                obj.optimalThresholdValMap = mapInsert(obj.optimalThresholdValMap, obj.slcKS{k}, optThreshold);
            end
        end%end
    end
    
end

