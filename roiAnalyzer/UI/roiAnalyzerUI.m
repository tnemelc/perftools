classdef roiAnalyzerUI < maskOverlayBaseUI & imSeriesUI 
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        roiAnlzrTool;
        featuresStrucUI;
        roiMaskPluginSelection;
        resultsSubPanelsTab;
    end
    
    %% public static method
    methods (Static)
        function obj = getInstance()
            persistent localObj;
            %which isvalid
            if isempty(localObj) %|| ~isvalid(localObj)
                localObj = roiAnalyzerUI;
            end
            obj = localObj;
        end
    end%methods (Static)

    methods (Access = public)
        %%
        function obj = initialize(obj, hParent, pluginInfo, opt)
            obj = obj.initialize@baseUI(hParent, pluginInfo, opt);
            obj = obj.initialize@imSeriesUI(hParent, pluginInfo, opt);
            obj = obj.initialize@maskOverlayBaseUI(hParent);
            obj = obj.initPatientPathUI(fullfile(obj.basePath, 'patientData', 'patientName', 'example'));
            obj = obj.initFeaturesStructUI();
            obj = obj.initRoiMaskPluginSelctionUI();
        end%initialize
        %%
        function obj = initFeaturesStructUI(obj)
            obj.featuresStrucUI.textUI = ...
                uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(1) obj.lin(10) 0.1 0.05],...
                'String', sprintf('feature to display'));
            
            obj.featuresStrucUI.popupUI = ...
                uicontrol(obj.lPanel, 'Style', 'popup',...
                'Units',  'normalized',...
                'Position', [obj.col(2) obj.lin(10) 0.4 obj.HdleHeight],...
                'String', {'rois', 'roiSurface' 'roiTicPeakVal', 'roiTicTtp', 'roiTicAuc', 'roiTicMaxSlope', 'roiTicMaxSlopePos', ...
                            'roiTicBaseLineLen', 'roiTicDelay', 'roiTicCnr', 'roiTicBaseLineStd', 'voxelTicPeakVal', 'voxelTicDelay', 'voxelTicCnr', ...
                            'voxelTicCnrAvgOfRoi', 'voxelTicBaselineStd', 'voxelTicBaselineStdAvgOfRoi', ...
                            'roi2vxlPeakValRelativeErr', 'roiAvgRoi2vxlPeakValRelativeErr', 'roi2vxlBaselineStdRatio',...
                            'roi2vxlTicRelativeSse', 'roiAvgRoi2vxlTicRelativeSse', 'none'}, ...
                'Callback', @obj.onfeatChoiceCb);
        end%initFeaturesStructUI
        %%
        function obj = initRoiMaskPluginSelctionUI(obj)
            obj.roiMaskPluginSelection.textUI = ...
                uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(1) obj.lin(8) 0.1 0.05],...
                'String', sprintf('rois mask plugin'));
            
            obj.roiMaskPluginSelection.popupUI = ...
                uicontrol(obj.lPanel, 'Style', 'popup',...
                'Units',  'normalized',...
                'Position', [obj.col(2) obj.lin(8) 0.4 obj.HdleHeight],...
                'String', {'segmentation/ManualMultiRoiMapDisplay', 'segmentation/AHA_Segments', 'strg', 'ticFeatures/dynamic_threshold_roi_growing', 'ticFeatures/autoRoiClustering'}, ...
                'Callback', @obj.roiMaskPluginSelectionCb);
        end%initRoiMaskPluginSelctionUI
        %%getters
        %%
        function featName = getFeatureName(obj)
            featList = get(obj.featuresStrucUI.popupUI, 'String');
            featName = char(featList(get(obj.featuresStrucUI.popupUI, 'Value')));
        end
        %%
        function pluginSel = getPluginSelection(obj)
            pluginListList = get(obj.roiMaskPluginSelection.popupUI, 'String');
            pluginSel = char(pluginListList(get(obj.roiMaskPluginSelection.popupUI, 'Value')));
        end%getPluginSelection
    end%methods (Access = public)
    
    methods (Access = protected)
        %%
        function goCb(obj, ~, ~)
            try
                obj.setFooterStr('running');
                clc
                obj.wipeResults();
                toolOpt.dataPath = obj.getDataPath();
                switch obj.getPluginSelection()
                    case 'segmentation/ManualMultiRoiMapDisplay'
                        obj.roiAnlzrTool = manualMultiRoiMapDisplayRoiAnalyzerTool();
                    case 'segmentation/AHA_Segments'
                        obj.roiAnlzrTool = bullseyeSegmentRoiAnalyzerTool();
                    case  'ticFeatures/autoRoiClustering'
                        obj.roiAnlzrTool = featuresDisplayRoiAnalyzerTool();
                    case 'ticFeatures/dynamic_threshold_roi_growing'
                        obj.roiAnlzrTool = featuresDisplayDynamicThreshRoiGrowingRoiAnalyzerTool();
                    case 'strg'
                        obj.roiAnlzrTool = kMeanStrgRoiAnalyzerTool();
                end
                obj.roiAnlzrTool = obj.roiAnlzrTool.prepare(toolOpt);
                obj.roiAnlzrTool = obj.roiAnlzrTool.run(toolOpt);
                obj.dispResults();
                obj.setFooterStr('running completed');
            catch e
                obj.setFooterStr('x_x something bad happened');
                rethrow(e)
            end
        end%goCb(obj)
        %%
        function dispResults(obj)
            if isempty(obj.roiAnlzrTool)
                return;
            end
            tGroup = uitabgroup('Parent', obj.rPanel);
            set(tGroup, 'BackgroundColor', 'black');
            obj.resultsSubPanelsTab(1) = uitab('Parent', tGroup, 'Title', '2D Maps');
            obj.resultsSubPanelsTab(2) = uitab('Parent', tGroup, 'Title', 'signature');
            obj.resultsSubPanelsTab(3) = uitab('Parent', tGroup, 'Title', 'spider');
            obj.dispOverlayMapsResults();
            %obj.dispRoiFeaturesSignature();
            %obj.dispRoiFeaturesSignatureSpiderStyle();
        end%dispResults
        
        %%
        function dispOverlayMapsResults(obj)
            isKS = obj.roiAnlzrTool.getSeriesKS();
            if isempty(obj.handleAxesTab)
                obj.handleAxesTab = tight_subplot(2, 2, [.05 .05], [.01 .01], [.01 .01], obj.resultsSubPanelsTab(1));
                pos = get(obj.handleAxesTab(4), 'pos');
                set(obj.handleAxesTab(4), 'pos', [(pos(1) + 0.1 * pos(1)) (pos(2) +  0.1 * pos(4)) (pos(3) * 0.85) (pos(4) * 0.85)]);
                set(obj.handleAxesTab(4), 'color', 'k');
            end
            
            for k = 1 : length(isKS)
                isName = char(isKS(k));
                axes(obj.handleAxesTab(k));
                imSerie = obj.roiAnlzrTool.getImserie(isName);
                ovlay = obj.getOverlay(isName);
                h = imagesc(overlay(obj.correctImage(imSerie(:, :, obj.slcTimePos)), ovlay));
                set(h, 'ButtonDownFcn', {@obj.onImgClick, isName});
                axis off image;
                colorbar('YColor', [1 1 1]); caxis([min(ovlay(:)) max(ovlay(:))]);
                obj.optimizeFocus(obj.handleAxesTab(k), obj.roiAnlzrTool.getMyoMask(isName));
                obj.displayMyoBoundaries(isName, obj.handleAxesTab(k));
                obj.displayRoiBoundaries(isName, obj.handleAxesTab(k))
                text('units', 'normalized', 'position', [0.5, 0.05], 'fontsize', 10,...
                    'color', 'white', 'string', ...
                    sprintf('%s, %d/%d', isName, obj.slcTimePos, size(imSerie, 3)));
            end
            set(gcf, 'WindowScrollWheelFcn', {@obj.onScrollCb, size(imSerie, 3)});
        end%dispOverlayMapsResults
        %%
        function displayRoiBoundaries(obj, isName, axisHdle)
            mask = obj.roiAnlzrTool.getRoisMask(isName);
            nbRois = max(mask(:));
            curRoiMask = zeros(size(mask));
            for k = 1 : nbRois
                curRoiMask(mask ~= k) = 0;
                curRoiMask(mask == k) = 1;
                bnds = obj.processMaskBounds(imdilate(curRoiMask, strel('disk', 1)));
                for m = 1 : length(bnds)
                    obj.boundariesPlot(bnds{m}, [0 0 1], axisHdle, 1);
                end
            end
        end%displayRoiBoundaries
        
        %%
        function displayMyoBoundaries(obj, isName, axisHdle)
            if nargin == 2
                axisHdle = gca;
            end
            bnds = obj.processMaskBounds(obj.roiAnlzrTool.getMyoMask(isName));
            obj.boundariesPlot(bnds{2}, [1 0 0], axisHdle, 2);
            obj.boundariesPlot(bnds{1}, [0 1 0], axisHdle, 2);
        end%displayMyoBoundaries
        %%
        function dispRoiFeaturesSignature(obj)
            ftSignatureAxesTab = tight_subplot(2, 2, [.05 .05], [.05 .05], [.05 .05],  obj.resultsSubPanelsTab(2));
            isKS = obj.roiAnlzrTool.getSeriesKS();
            ftSet = {'PeakVal', 'Ttp', 'Auc', 'MaxSlope', 'MaxSlopePos', 'Delay'};
            colors = [0, 0.4470, 0.7410;...
                0.8500, 0.3250, 0.0980;...
                0.9290, 0.6940, 0.1250;...
                0.4940, 0.1840, 0.5560;...
                0.4660, 0.6740, 0.1880;...
                0.3010, 0.7450, 0.9330;...
                0.6350, 0.0780, 0.1840];
            
            for k = 1 : length(isKS)
                roisMask = obj.roiAnlzrTool.getFeaturesMask('rois', isKS{k});
                nbRois = max(roisMask(:));
                lgdKS = {};
                ftArray = nan(length(ftSet), nbRois);
                
                for m = 1 : length(ftSet)
                    ftMask = obj.roiAnlzrTool.getFeaturesMask(['roiTic' ftSet{m}], isKS{k});
                    for n = 1 : nbRois
                        ftArray(m, n) = ftMask(find(roisMask == n, 1, 'first'));
                        lgdKS = [lgdKS sprintf('%s', obj.roiAnlzrTool.getRoiLabel(isKS{k}, n))];
                    end
                end
                normftArray = obj.normalizeFeaturesArray(ftArray);
                axes(ftSignatureAxesTab(k)); hold on;
                for m = 1 : nbRois
                    plot(normftArray(:, m), 'color', colors(m, :));
                end
                xlim([0  length(ftSet) + 1]);
                ylim([0 1.1]);
                set(gca, 'xtick', 1 : length(ftSet), 'xticklabel', ftSet, 'fontsize', 8);
                grid;
                legend(lgdKS);
            end
            %set axes color configuration AFTER plot.
            for k = 1 : length(ftSignatureAxesTab)
                if k <= length(isKS)
                    set(ftSignatureAxesTab(k), 'XColor', [1 1 1]);
                    set(ftSignatureAxesTab(k), 'YColor', [1 1 1]);
                end
                set(ftSignatureAxesTab(k), 'color', [0 0 0]);
            end
        end%dispRoiFeaturesSignature
        %%
        function dispRoiFeaturesSignatureSpiderStyle(obj)
            ftSignatureAxesTab = tight_subplot(2, 2, [.05 .05], [.05 .05], [.05 .05],  obj.resultsSubPanelsTab(3));
            isKS = obj.roiAnlzrTool.getSeriesKS();
            ftSet = {'PeakVal'; 'Ttp'; 'Auc'; 'MaxSlope'; 'MaxSlopePos'; 'Delay'};
            
            % Axes properties
            axes_interval = 2;
            axes_precision = 1;
            for k = 1 : length(isKS)
                roisMask = obj.roiAnlzrTool.getFeaturesMask('rois', isKS{k});
                nbRois = max(roisMask(:));
                lgdKS = {};
                ftArray = nan(length(ftSet), nbRois);
                for m = 1 : length(ftSet)
                    ftMask = obj.roiAnlzrTool.getFeaturesMask(['roiTic' ftSet{m}], isKS{k});
                    for n = 1 : nbRois
                        ftArray(m, n) = ftMask(find(roisMask == n, 1, 'first'));
                        lgdKS = [lgdKS sprintf('%s', obj.roiAnlzrTool.getRoiLabel(isKS{k}, n))];
                    end
                end
                axes(ftSignatureAxesTab(k));
                normftArray = obj.normalizeFeaturesArray(ftArray);
                spider_plot(normftArray', ftSet, axes_interval, axes_precision,...
                    'Marker', 'o',...
                    'LineStyle', '-',...
                    'LineWidth', 2,...
                    'MarkerSize', 5)
%                 legend(lgdKS);
            end
            %set axes color configuration AFTER plot.
            for k = 1 : length(ftSignatureAxesTab)
                if k <= length(isKS)
                    set(ftSignatureAxesTab(k), 'XColor', [1 1 1]);
                    set(ftSignatureAxesTab(k), 'YColor', [1 1 1]);
                end
                set(ftSignatureAxesTab(k), 'color', [0 0 0]);
            end
        end%dispRoiFeaturesSignatureSpiderStyle
        %%
        function ftArray = normalizeFeaturesArray(obj, ftArray)
            for k = 1 : size(ftArray, 1)
                maxVal = max(ftArray(k, :));
                minVal = 0;%min(ftArray(k, :));
                for m = 1 : size(ftArray, 2)
                    ftArray(k, m) = (ftArray(k, m) - minVal) / (maxVal - minVal);
                end
            end
        end%normalizeFeaturesArray
        %%
        function mask = getOverlay(obj, isName)
            %mask = obj.roiAnlzrTool.getRoisMask(isName);
            mask = obj.roiAnlzrTool.getFeaturesMask(obj.getFeatureName(), isName);
        end%getOverlay
        %%
        function onScrollCb(obj, ~, arg2, maxPosValue)
            obj.onScrollCb@imSeriesUI([], arg2, maxPosValue);
            obj.dispOverlayMapsResults();
        end%onScrollCb
        %%
        function [x, y] = onImgClick(obj, arg1, arg2, isName)
            [x, y] = obj.onImgClick@imSeriesUI(arg1, arg2, isName);
            switch obj.maskEditMode;
                case 'none'
                    roisMask = obj.roiAnlzrTool.getRoisMask(isName);
                    ftMask = obj.getOverlay(isName);
                    roiId = roisMask(x, y);
                    roiSurface = obj.roiAnlzrTool.getRoiSurface(isName, roiId);
                    obj.setFooterStr(sprintf('clicked on %s (%d, %d) | roi#:%d | roi Surface: %d voxels | feat value: %0.02f', isName, x, y, roiId, roiSurface, ftMask(x, y)));
                    
                    lgdKS = {};
                    cla(obj.handleAxesTab(4));
                    axes(obj.handleAxesTab(4));
                    ticTAcq = obj.roiAnlzrTool.getTAcqVector(isName);
                    avgTic = obj.roiAnlzrTool.getRoiAvgTic(isName, roiId);
                    vxlTic = obj.roiAnlzrTool.getVoxelTic(isName, x, y);
                    minTic = obj.roiAnlzrTool.getRoiMinTic(isName, roiId);
                    maxTic = obj.roiAnlzrTool.getRoiMaxTic(isName, roiId);
                    % time intensity curves
                    plot(ticTAcq, avgTic, 'color', [0 0.5 0]); lgdKS = [lgdKS 'avg roi tic']; hold on;
                    plot(ticTAcq, vxlTic, 'color', [0 0 0.8]); lgdKS = [lgdKS 'clicked vxl tic'];
                    fillPlot(ticTAcq', minTic', maxTic'); lgdKS = [lgdKS 'min/max values'];
                    %aif
                    [aif, aifTAcq] = obj.roiAnlzrTool.getAifTic();
                    plot(aifTAcq, aif * 2, 'r'); lgdKS = [lgdKS 'aif tic'];
                    %indicators (peakPos, tic foot, etc...)
                    %roi tic
                    [footVal, footDate] = obj.roiAnlzrTool.getRoiTicFoot(isName, roiId);
                    plot(footDate, footVal, 'o', 'color', [0 .5 0]);
                    [peakVal, peakDate] = obj.roiAnlzrTool.getRoiTicPeak(isName, roiId);
                    plot(peakDate, peakVal, 'o', 'color', [0 .5 0]);
                    %voxel tic
                    [footVal, footDate] = obj.roiAnlzrTool.getVoxelTicFoot(isName, x, y);
                    plot(footDate, footVal, 'o', 'color', [0 0 .8]);
                    [peakVal, peakDate] = obj.roiAnlzrTool.getVoxelTicPeak(isName, x, y);
                    plot(peakDate, peakVal, 'o', 'color', [0 0 .8]);
                    
                    
                    
                    plot(obj.roiAnlzrTool.getAifFeature('footDate'),...
                                        2 * aif(obj.roiAnlzrTool.getAifFeature('footPos')), 'or');
                    hl = legend(lgdKS);
                    upperGraphVal = max(maxTic(:)) + 0.05 * max(maxTic(:));
                    
                    set(obj.handleAxesTab(4), 'xtick', 0 : 10 : ticTAcq(end), 'xticklabel', 0 : 10 : ticTAcq(end));
                    set(obj.handleAxesTab(4), 'ytick', [0 round(max(avgTic)) upperGraphVal], 'yticklabel', [0 round(max(avgTic)) upperGraphVal]);
                    set(obj.handleAxesTab(4), 'XMinorTick', 'on', 'YMinorTick', 'on')
                    set(obj.handleAxesTab(4), 'XColor', [1 1 1]);
                    set(obj.handleAxesTab(4), 'YColor', [1 1 1]);
                    set(obj.handleAxesTab(4), 'color', [0 0 0]);
                    
                    % axis limits
                    xlim([0, ticTAcq(end)]);
                    ylim([0, upperGraphVal]);
                    
                    %legend
                    set(hl, 'textColor', 'w');
                    set(hl, 'fontsize', 8);
                    set(hl, 'location', 'northwest');
                otherwise
                    opt.isName = isName;
                    obj.startMaskEditCb(obj.getOverlay(isName), opt);
            end%switch
            
        end%onImgClick
        %%
        function saveCb(obj, ~, ~)
            try
                xml.root.date = date;
                xml.root.aif.ticFoot = obj.roiAnlzrTool.getAifFeature('footPos');
                xml.root.aif.baselineLength = obj.roiAnlzrTool.getAifFeature('footDate');
                xml.root.aif.firstPassEndDate = obj.roiAnlzrTool.getAifFeature('firstPassEndDate');
                isKS = obj.roiAnlzrTool.getSeriesKS();
                for k = 1 : length(isKS)
                    isName = isKS{k};
                    roisMask = obj.roiAnlzrTool.getRoisMask(isName);
                    xml.root.(isName).nbRoi = max(roisMask(:));
                    peakValMask = obj.roiAnlzrTool.getFeaturesMask('roiTicPeakVal', isName);
                    ttpMask = obj.roiAnlzrTool.getFeaturesMask('roiTicTtp', isName);
                    aucMask = obj.roiAnlzrTool.getFeaturesMask('roiTicAuc', isName);
                    maxSlopeMask = obj.roiAnlzrTool.getFeaturesMask('roiTicMaxSlope', isName);
                    maxSlopePosMask = obj.roiAnlzrTool.getFeaturesMask('roiTicMaxSlopePos', isName);
                    delayMask = obj.roiAnlzrTool.getFeaturesMask('roiTicDelay', isName);
                    
                    for m = 1 : max(roisMask(:))
                        switch obj.getPluginSelection()
                            case 'segmentation/ManualMultiRoiMapDisplay'
                                xml.root.(isName).roi{m}.label = obj.roiAnlzrTool.getRoiLabel(isName, m);
                            case 'ticFeatures/dynamic_threshold_roi_growing'
                                xml.root.(isName).roi{m}.label = 'lesion';
                        end
                        val = peakValMask(roisMask == m);
                        xml.root.(isName).roi{m}.peakVal = val(1);
                        val = ttpMask(roisMask == m);
                        xml.root.(isName).roi{m}.ttp = val(1);
                        val = aucMask(roisMask == m);
                        xml.root.(isName).roi{m}.auc = val(1);
                        val = maxSlopeMask(roisMask == m);
                        xml.root.(isName).roi{m}.maxSlope = val(1);
                        val = maxSlopePosMask(roisMask == m);
                        xml.root.(isName).roi{m}.maxSlopePos = val(1);
                        val = delayMask(roisMask == m);
                        xml.root.(isName).roi{m}.delay = val(1);
                    end
                end
                struct2xml(xml, fullfile(obj.getSavePath(), 'summary.xml'));
            catch e
                obj.setFooterStr('x_x something bad happened');    
            end
            obj.setFooterStr('saving completed succesfully');
        end%saveCb(obj)
        %%
        function onfeatChoiceCb(obj, ~, ~)
            obj.dispOverlayMapsResults();
        end%onfeatChoiceCb
        %%
        function validKey = onKeyPressCb(obj, ~, arg)
            validKey = obj.onKeyPressCb@baseUI([], arg);
%             obj.lgr.warn('function to be written');
%             return;
            
            if validKey
                obj.displayMapOverlay();
                return
            end
            prevMode = obj.maskEditMode;
            validKey = obj.onKeyPressCb@maskOverlayBaseUI([], arg);
            if strcmp('none', obj.maskEditMode) && ...
                    (strcmp('eraser', prevMode) || strcmp('pencil', prevMode))
                obj.featTool.saveMyoMaskUpdate();
            end
        end%onKeyPressCb
        %%
        function obj = browsePatientPathCb(obj, ~, ~)
            obj = obj.browsePatientPathCb@baseUI();
            obj.updateSavePath(fullfile('roiAnalyzer', obj.getPluginSelection()));
        end%browsePatientPathCb
        %%
        function roiMaskPluginSelectionCb(obj, ~, ~)
            obj.updateSavePath(fullfile('roiAnalyzer', obj.getPluginSelection()));
        end
        %% mask edit
        %%
        function [mask, x, y] = maskEditCb(obj, arg1, ~, opt)
            mask = obj.maskEditCb@maskOverlayBaseUI(arg1, [], opt);
            if ~isnan(mask)
                mask(mask > 0) = 1;
%                 obj.roiAnlzrTool.updateMyoMask(opt.isName, mask);
                obj.roiAnlzrTool.updateMaskMaps(opt.isName, mask);
            end
            axes(gca);
            imagesc(mask);
            axis off image;
%             obj.optimizeFocus(gca, obj.roiAnlzrTool.getfirstRoiMask(opt.isName));
            %obj.displayMapOverlay();
        end
    end%methods (Access = protected)
    
end

