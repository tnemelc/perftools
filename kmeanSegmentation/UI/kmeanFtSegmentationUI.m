classdef kmeanFtSegmentationUI < imSeriesUI & maskOverlayBaseUI & sliderListUI
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ticSegmentationTool;
        featuresStrucUI;
    end
    %% public static method
    methods (Static)
        function obj = getInstance()
            persistent localObj;
            %which isvalid
            if isempty(localObj) %|| ~isvalid(localObj)
                localObj = kmeanFtSegmentationUI;
            end
            obj = localObj;
        end
    end%methods (Static)

    methods (Access = public)
        %%
        function obj = initialize(obj, hParent, pluginInfo, opt)
            obj = obj.initialize@imSeriesUI(hParent, pluginInfo, opt);
            obj = obj.initialize@maskOverlayBaseUI(hParent);
            obj = obj.initDataPathUI(fullfile(obj.basePath, 'patientData', 'patientName'));
            obj = obj.initFeaturesStructUI();
        end
        %%
        function mask = getOverlay(obj, isName)
            %mask = obj.ticSegmentationTool.getRoisMask(isName);
            mask = obj.ticSegmentationTool.getFeaturesMask(obj.getFeatureName(), isName);
        end%getOverlay
        %%
        function featName = getFeatureName(obj)
            featList = get(obj.featuresStrucUI.popupUI, 'String');
            featName = char(featList(get(obj.featuresStrucUI.popupUI, 'Value')));
        end
    end
    
    %% protected methods
    methods (Access = protected)
        %%
        function obj = initFeaturesStructUI(obj)
            obj.featuresStrucUI.textUI = ...
                uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(1) obj.lin(10) 0.1 0.05],...
                'String', sprintf('feature'));
            
            obj.featuresStrucUI.popupUI = ...
                uicontrol(obj.lPanel, 'Style', 'popup',...
                'Units',  'normalized',...
                'Position', [obj.col(2) obj.lin(10) 0.4 obj.HdleHeight],...
                'String', { 'voxelTicAuc', 'voxelTicPeakVal', 'voxelTicMaxSlope', 'voxelTicCnr', ...
                            'voxelTicCnrAvgOfRoi', 'voxelTicBaselineStd', 'voxelTicBaselineStdAvgOfRoi', ...
                            'none'}, ...
                'Callback', @obj.dispResults);
        end
        %%
        function obj = dispResults(obj, ~, ~)
            clc;
            isKS = obj.ticSegmentationTool.getSeriesKS();
            if isempty(obj.handleAxesTab)
                obj.handleAxesTab = tight_subplot(2, 2, [.05 .05], [.01 .01], [.01 .01], obj.rPanel);
                pos = get(obj.handleAxesTab(4), 'pos');
                set(obj.handleAxesTab(4), 'pos', [(pos(1) + 0.1 * pos(1)) (pos(2) +  0.1 * pos(4)) (pos(3) * 0.85) (pos(4) * 0.85)]);
            end
            
            for k = 1 : length(isKS)
                isName = char(isKS(k));
                axes(obj.handleAxesTab(k));
                imSerie = obj.ticSegmentationTool.getImserie(isName);
                ovlay = obj.getOverlay(isName);
                h = imagesc(overlay(obj.correctImage(imSerie(:, :, obj.slcTimePos)), ovlay));
                set(h, 'ButtonDownFcn', {@obj.onImgClick, isName});
                axis off image;
                colorbar('YColor', [1 1 1]); caxis([min(ovlay(:)) max(ovlay(:))]);
                obj.optimizeFocus(obj.handleAxesTab(k), obj.ticSegmentationTool.getMyoMask(isName));
                text('units', 'normalized', 'position', [0.5, 0.05], 'fontsize', 10,...
                    'color', 'white', 'string', ...
                    sprintf('%s, %d/%d', isName, obj.slcTimePos, size(imSerie, 3)));
                set(gcf, 'WindowScrollWheelFcn', {@obj.onScrollCb, size(imSerie, 3)});
                obj.displayRoisBoundaries(isName, obj.handleAxesTab(k))
            end
            set(obj.handleAxesTab(4), 'color', zeros(1, 3));
        end%dispResults
        %% Callback functions
        %%
        function obj = goCb(obj, ~, ~)
            obj.setFooterStr('running...');
            clc;
            try
                obj.ticSegmentationTool = ticFeatKMeanSegmentationTool();
                toolOpt.dataPath = obj.getDataPath();
                obj.ticSegmentationTool = obj.ticSegmentationTool.prepare(toolOpt);
                obj.ticSegmentationTool = obj.ticSegmentationTool.run(toolOpt);
                obj.dispResults();
            catch e
                obj.setFooterStr('x_x something bad happened');
                rethrow(e);
            end
            obj.setFooterStr('running completed successfully');
        end
        %%
        function displayRoisBoundaries(obj, isName, axisHdle)
            if nargin == 2
                isName = gca;
            end
            roisMask = obj.ticSegmentationTool.getRoisMask(isName);
            nbRois = max(roisMask(:));
            cmap = jet(nbRois);
            for k = 1 : nbRois
                curMask = roisMask;
                curMask(curMask ~= k) = 0; 
                bnds = obj.processMaskBounds(curMask);
                
                for m = 1 : length(bnds)
                    if size(bnds{m}, 1) > 5
                        obj.boundariesPlot(bnds{m}, cmap(k, :), axisHdle, 2);
                    end
                end
            end
%             obj.boundariesPlot(bnds{2}, [0 1 0], axisHdle, 2);
        end%displayMyoBoundaries
        
        %%
        function obj = saveCb(obj, ~, ~)
            isKS = obj.ticSegmentationTool.getSeriesKS();
            try
                emptyDir(obj.getSavePath());
                for k = 1 : length(isKS)
                    isName = isKS{k};
                    mkdir(obj.getSavePath(), isName);
                    roiMask = obj.ticSegmentationTool.getRoisMask(isName);
                    savemat(fullfile(obj.getSavePath(), isName, 'roisMask.mat'), roiMask);
                end
            catch e
                obj.setFooterStr('x_x something bad happened');
                rethrow(e);
            end
            obj.setFooterStr('save completed successfully');
        end
        
        %%
        function onScrollCb(obj, ~, arg2, maxPosValue)
            obj.onScrollCb@imSeriesUI([], arg2, maxPosValue);
            obj.dispResults();
        end
        %%
        function validKey = onKeyPressCb(obj, ~, arg, arg2)
            if isfield(arg, 'Key')
                validKey = obj.onKeyPressCb@maskOverlayBaseUI([], arg);
            elseif isfield(arg2, 'Key');
                validKey = obj.onKeyPressCb@maskOverlayBaseUI([], arg2);
            else
                throw(MException('maskOverlayBaseUI:onKeyPressCb', 'key is not specified'));
            end
            
            if validKey
                obj.dispResults();
            end
        end%onKeyPressCb
        
        %%
        function obj = browsePatientPathCb(obj, ~, ~)
            obj = obj.browsePatientPathCb@baseUI();
            obj.updateSavePath('kmeanSegmentation');
        end%browsePatientPathCb
    end
    
end

