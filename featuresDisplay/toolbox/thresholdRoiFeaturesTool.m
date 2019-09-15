classdef thresholdRoiFeaturesTool < thresholdFeatProcessingTool
    %thresholdRoiFeaturesTool: this class searches the myocardium 
    % 
    
    properties
        roisMaskMap;
        thresholdVectMap;
    end
    
    methods (Access = public)
        %%
        function obj = run(obj)
            debug = true;
            obj = obj.loadSlcSerie();
            obj = obj.loadMyoMask();
            k = 1;
            while ~obj.checkMyoMaskEmpty()
                opt.iter = k;
                obj.lgr.info(sprintf('iteration %d', k));
                opt.rootPath = fullfile(obj.patientPath, 'featuresDisplay', class(obj), sprintf('iter%03d', opt.iter));
                %extract features
                obj = obj.loadThresholdFeaturesMap(opt);
                %load threshold Roi Mask
                obj = obj.loadSlcFirstRoiMask(opt);
                obj = obj.updateSeedMask(opt);
                %load AUC Mask
                obj = obj.loadSlcAUCMask();
                
                obj = obj.processFeatVect();
                obj = obj.normalizeFeatures();
                obj = obj.processThresholdFeatGradientsVect();
                obj = obj.processThresholdNormalizedFeatGradientsVect(opt);
                % create the mask from normalized gradient
                obj = obj.extractSlcRois(opt);
                opt.maskPath = fullfile(obj.patientPath, 'featuresDisplay', class(obj), sprintf('iter%03d', opt.iter));
                obj.saveMyoMasks(opt);
                k = k + 1;
                if debug
                    figureMgr.getInstance().newFig('myoMask');
                    for l = 1 : length(obj.slcKS)
                        subplot(1, 3, l);
                        imagesc(obj.myoMaskMap(char(obj.slcKS(l))));
                        axis off image;
                    end
                end
            end%while
            figureMgr.getInstance().closeFig('myoMask');
            % at the very end reload the original myoMask
            obj = obj.loadMyoMask();
        end%run
        %%
        function tmp = updatemaskMaps(obj, slcName, mask)
            tmp = obj.updatemaskMaps@thresholdFeatProcessingTool(slcName, mask);
            obj.roisMaskMap(slcName) = obj.roisMaskMap(slcName) .* mask + tmp;
        end%updatemaskMaps
        %%
        function clearMyocardialBorders(obj)
            for k = 1 : length(obj.slcKS)
                slcName = char(obj.slcKS(k));
                curMyoMask = obj.myoMaskMap(slcName);
                curRoiMask = obj.roisMaskMap(slcName);
                myoBorders = curMyoMask - imerode(curMyoMask, strel('disk', 1));
                
                %eliminate borders voxel owning to a single voxel roi
                bordersPos = find(myoBorders == 1);
                for l = 1 : length(bordersPos)
                    vxlPosList = find(curRoiMask == curRoiMask(bordersPos(l)));
                    if min(myoBorders(vxlPosList))
                        curMyoMask(bordersPos(l)) = 0;
                    end
                end
                obj.myoMaskMap = mapInsert(obj.myoMaskMap, slcName, curMyoMask);
                obj.updatemaskMaps(slcName, curMyoMask);
            end
        end%clearMyocardialBorders
        %% getters
        %%
        function roisMask = getRoisMask(obj, slcName)
            roisMask = obj.roisMaskMap(slcName);
        end%getRoisMask
        %%
        function roiId = getRoiId(obj, slcName, x, y)
            roisMask = obj.roisMaskMap(slcName);
            roiId = roisMask(x, y);
        end%getRoiId
        %%
        function threshRoisMask = getThreshoRoisMask(obj, slcName)
            roisMask = obj.roisMaskMap(slcName);
            threshRoisMask = zeros(size(roisMask));
            threshVect = obj.thresholdVectMap(slcName);
            for k = 1 : max(roisMask(:))
                threshRoisMask(roisMask == k) = threshVect(k);
            end
        end%getThreshoRoisMask
        %%
        function normFtGdtVect = getNormFtGdtVect(obj, slcName, roiId)
            
        end%
    end% methods (Access = public)
    
    methods (Access = protected)
        %%
        function obj = extractSlcRois(obj, opt)
            for k = 1 : length(obj.slcKS)
                slcName = char(obj.slcKS(k));
                curMask = obj.firstRoiMaskMap(slcName);
                
                curNormalizedGradient = obj.slcThreshRoiNormalizedFeaturesGradientsNormMap(slcName);
%                 optimThresh = find(curNormalizedGradient == max(curNormalizedGradient), 1, 'first');
                optimThresh = find(curNormalizedGradient > 0.8 * max(curNormalizedGradient), 1, 'first');
                if isempty(optimThresh)
                    optimThresh = 1;
                end
                curMask(curMask > optimThresh) = 0;
                curMask(curMask > 0) = opt.iter;
                if opt.iter > 1
                    curRoisMask = obj.roisMaskMap(slcName);
                    %check that new roi does not own to another one
                    if ~isempty(intersect(find(curRoisMask > 0), find(curMask > 0)))
                        throw(MException('thresholdRoiFeaturesTool:extractSlcRois', 'a voxel cannot be common to two regions'));
                    end
                    obj.roisMaskMap = mapInsert(obj.roisMaskMap, slcName, curRoisMask + curMask);
                    thresholdVect = obj.thresholdVectMap(slcName);
                    obj.thresholdVectMap = mapInsert(obj.thresholdVectMap, slcName, [thresholdVect, optimThresh]);
                else
                    obj.roisMaskMap = mapInsert(obj.roisMaskMap, slcName, curMask);
                    obj.thresholdVectMap = mapInsert(obj.thresholdVectMap, slcName, optimThresh);
                end
                %update myocard mask
                myoMask = obj.myoMaskMap(slcName);
                myoMask(curMask > 0) = 0;
                obj.myoMaskMap = mapInsert(obj.myoMaskMap, slcName, myoMask);
            end
        end%extractRoi
        %%
        function obj = updateSeedMask(obj, opt)
            for k = 1 : length(obj.slcKS)
                slcName = char(obj.slcKS(k));
                seedMask = opt.iter .* loadmat(fullfile(opt.rootPath, char(obj.slcKS(k)), 'seedMask.mat'));
                try 
                    obj.seedMaskMap = mapInsert(obj.seedMaskMap, slcName, seedMask + obj.seedMaskMap(slcName));
                catch
                    obj.seedMaskMap = mapInsert(obj.seedMaskMap, slcName, seedMask);
                end
            end
        end%updateSeedMask
        %%
        function saveMyoMasks(obj, opt)
            for k = 1 : length(obj.slcKS)
                slcName = char(obj.slcKS(k));
                savemat(fullfile(opt.maskPath, slcName, 'mask.mat'), obj.myoMaskMap(slcName));
            end% saveMyoMasks
        end% saveMyoMasks
        %%
        function retVal = checkMyoMaskEmpty(obj)
            retVal = true;
            for k = 1 : length(obj.slcKS)
                curMask = obj.myoMaskMap(char(obj.slcKS(k)));
                if max(curMask(:))
                    retVal = false;
                    return;
                end
            end% saveMyoMasks
        end%checkMyoMaskEmpty
        %%
        function obj = loadSlcAUCMask(obj)
            for k = 1 : length(obj.slcKS)
                try
                    mask = loadmat(fullfile(obj.patientPath, 'featuresDisplay', char(obj.slcKS(k)), 'AUCMask.mat'));
                catch
                    obj.lgr.info('no AUC mask, will load myo mask instead');
                    mask = loadmat(fullfile(obj.patientPath, 'dataPrep', char(obj.slcKS(k)), 'mask.mat'));
                end
                obj.AUCMaskMap = mapInsert(obj.AUCMaskMap, char(obj.slcKS(k)), mask);
            end
        end%loadSlcAUCMask
    end%methods (Access = protected)
end

