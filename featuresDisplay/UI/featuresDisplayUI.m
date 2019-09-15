classdef featuresDisplayUI < imSeriesUI & maskOverlayBaseUI & sliderListUI
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
        properties(Access = protected)
            dimChoiceUIStructTab;
            isPanelHdleParent;
            featuresTypeUIStruct;
            overlayTypeUIStruct;
            featNumberUIStruct;
            featTool;
            dimKS;
        end

%% public static method
methods (Static)
    function obj = getInstance()
        persistent localObj;
            %which isvalid
            if isempty(localObj) %|| ~isvalid(localObj)
                localObj = featuresDisplayUI;
            end
            obj = localObj;
    end
end%methods (Static)

    %% public methods
    methods (Access = public)
        function obj = initialize(obj, hParent, pluginInfo, opt)
            obj = obj.initialize@imSeriesUI(hParent, pluginInfo, opt);
            obj.lin = 0.95 : - 0.05 : 0.1;
            obj.col = 0.1 : 0.1 : 0.9;
            
            obj = obj.initialize@maskOverlayBaseUI(hParent);
            obj = obj.initPatientPathUI(fullfile(obj.basePath, 'patientData', 'patientName'));
            obj.initFeatNumber();
            obj.initDimensionUI();
            obj.initFeaturesTypeUI();
            obj.initOverlayTypeUI();
            obj.initSldrParameters();
            obj.updateSavePath('featuresDisplay');
        end%initialize
        %%
        function obj = initDimensionUI(obj)
            for k = 1 : 8
                obj.dimChoiceUIStructTab.textUITab(k) = ...
                    uicontrol(obj.lPanel, 'Style', 'text',...
                    'Units',  'normalized',...
                    'Position', [obj.col(1) obj.lin(k + 1) 0.1 0.05],...
                    'String', sprintf('dimension %d', k));
                obj.dimChoiceUIStructTab.popupUITab(k) = ...
                    uicontrol(obj.lPanel, 'Style', 'popup',...
                    'Units',  'normalized',...
                    'Position', [obj.col(2) obj.lin(k + 1) 0.4 obj.HdleHeight],...
                    'String', {'TTP', 'AUC', 'maxSlope', 'TTPStd',  'AUCStd', 'maxSlopeStd', 'maxSlopePos', 'PeakVal', 'PeakValStd', 'roiSurface'});
                set(obj.dimChoiceUIStructTab.popupUITab(k), 'value', k);
                if k > obj.getFeatNumber()
                    set(obj.dimChoiceUIStructTab.textUITab(k), 'visible', 'off');
                    set(obj.dimChoiceUIStructTab.popupUITab(k), 'visible', 'off');
                end
            end
        end%initDimensionUI
        %%
        function obj = initFeaturesTypeUI(obj)
            obj.featuresTypeUIStruct.textUI = ...
                uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(1) obj.lin(10) 0.1 0.05],...
                'String', sprintf('features type'));
            
            obj.featuresTypeUIStruct.popupUI = ...
                uicontrol(obj.lPanel, 'Style', 'popup',...
                'Units',  'normalized',...
                'Position', [obj.col(2) obj.lin(10) 0.4 obj.HdleHeight],...
                'String', {'patient_reference', 'dynamic_thresh_roi_growing', 'kMean_STRG', 'patient_voxels_Features', 'homogeneousFeaturesRois'});
        end%featuresTypeUIStructTab
        %%
        function obj = initOverlayTypeUI(obj)
            obj.overlayTypeUIStruct.textUI = ...
                uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(1) obj.lin(11) 0.1 0.05],...
                'String', sprintf('overlay type'));
            
            obj.overlayTypeUIStruct.popupUI =...
                uicontrol(obj.lPanel, 'Style', 'popup',...
                'Units',  'normalized',...
                'Position', [obj.col(2) obj.lin(11) 0.4 obj.HdleHeight],...
                'String', {'firstRoiMap', 'roisMap', 'seed', 'delayMap', 'TTPMap', 'AUCMask', 'maxSlopeMap', 'threshold', 'none'},...
                'Callback', @obj.overlayChoiceCb);
            
        end%initOverlayTypeUI
        %%
        function obj = initFeatNumber(obj, nbFeat)
          obj.featNumberUIStruct.textUI = ...
                uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(1) obj.lin(1) 0.1 0.05],...
                'String', sprintf('# of features'));
            
            obj.featNumberUIStruct.popupUI =...
                uicontrol(obj.lPanel, 'Style', 'popup',...
                'Units',  'normalized',...
                'Position', [obj.col(2) obj.lin(1) 0.4 obj.HdleHeight],...
                'String', {'3', '4', '5', '6', '7', '8'},...
                'Callback', @obj.featNumberChoiceCb);
            if nargin > 1
                set(obj.featNumberUIStruct.popupUI, 'value', nbFeat - 2);
            end
        end%initDimNumber
        %%
        function obj = initSldrParameters(obj)
            obj.slrData.keySet =     {'base',   'mid',  'apex'}; % append set name here
            obj.slrData.initValSet = {  10,      10,       10   }; %append new param init value
            obj.slrData.minValSet =  {   0,       0,        0   }; %append new param min value
            obj.slrData.maxValSet =  {  10,      10,       10   };%append new param max value
            obj.slrData.factorSet =  {   1,       1,        1   };%append new factor value (1 if no need to factor)
            obj.slrData.unitSet =    {'AU',    'AU',     'AU'  };%append unit string
            
            obj = obj.initParamLayoutStructure(0.4, 0.2);
            obj = obj.initParametersMaps();
            obj.dispParamSldr();
        end%initParametersMap
        %%
        function nbFeat = getFeatNumber(obj)
            nbFeat = get(obj.featNumberUIStruct.popupUI, 'Value') + 2;
        end%getFeatNumber
        %%
        function maxOverlayValue = getMaxOverlayValue(obj, slcName)
            maxOverlayValue = obj.getSldrValue(slcName);
        end%getmaxOverlayValue
    end%methods (Access = public)
    
    %% protected methods
    methods (Access = protected)
        %% Callback functions
        %%
        function obj = goCb(obj, ~, ~)
            obj.setFooterStr('start running');
            obj.wipeResults();
            clc;
            try
                figureMgr.getInstance().closeAllBut('deconvTool');
                obj.dimKS = {};
                for k = 1 : getFeatNumber(obj)
                    obj.dimKS = [obj.dimKS obj.getDimensionName(k)];
                end
                switch getFeatureType(obj)
                    case 'dynamic_thresh_roi_growing'
                        obj.featTool = thresholdFeatProcessingTool();
                    case 'kMean_STRG'
                        obj.featTool = kMeanSTRGFeatTool();
                    case 'patient_reference'
                        obj.featTool = refFeatExtractTool();
                    case 'patient_voxels_Features'
                        obj.featTool = voxelFeatExtractTool();
                    case 'homogeneousFeaturesRois'
                        obj.featTool = thresholdRoiFeaturesTool();
                end%switch
                toolOpt.dataPath = obj.getDataPath();
                toolOpt.dimKS = obj.dimKS;
                obj.featTool = obj.featTool.prepare(toolOpt);
                obj.featTool = obj.featTool.run();
                obj.dispResults();
            catch e
                obj.setFooterStr('x_x something bad happened');
                rethrow(e);
            end
            obj.setFooterStr('running completed');
        end%goCb
        %%
        function obj = saveCb(obj, ~, ~)
            obj.setFooterStr('start save');
            if ~isdir(fullfile(obj.getSavePath(), obj.getFeatureType(), 'figures'))
                mkdir(fullfile(obj.getSavePath(), obj.getFeatureType(), 'figures'));
            end
            figureMgr.getInstance.saveAll(fullfile(obj.getSavePath(), obj.getFeatureType(), 'figures'));
            summary.root.features = obj.getFeatParams();
            summary.root.threshVals = obj.getSldrValueList();
            struct2xml(summary, fullfile(obj.getSavePath(), obj.getFeatureType(), 'summary.xml'));
            %save results frames
            obj.saveResultsFrames( fullfile(obj.getSavePath(), obj.getFeatureType()) );
            
            switch obj.getFeatureType()
                case 'dynamic_thresh_roi_growing'
                    %save masks as a unique roi matching optimal threshold
                    isKS = obj.featTool.getSliceKS();
                    for m = 1 : length(isKS)
                        isName = char(isKS(m));
                        mask = obj.featTool.getfirstRoiMask(isName);
                        mask(mask > obj.featTool.getOptThreshVal(isName)) = 0;
                        mask(mask > 0) = 1;
                        if ~isdir(fullfile(obj.getSavePath(), obj.getFeatureType(), isName))
                            mkdir(fullfile(obj.getSavePath(), obj.getFeatureType(), isName));
                        end
                        savemat(fullfile(obj.getSavePath(), obj.getFeatureType(), isName, 'roisMask.mat'), mask);
                    end
                otherwise
                    obj.lgr.warn('mask saving not implemented for this approach');
            end
            obj.setFooterStr('save completed');
        end%saveCb    
        %%
        function overlayChoiceCb(obj, ~, ~)
            if ~isempty(obj.featTool)
                switch obj.getOverlayType()
                    case 'firstRoiMap'
                        obj.updateOverlayControls();
                    case 'AUCMask'
                        obj.updateOverlayControls();
                    case 'roisMap'
                        obj.updateOverlayControls();
                    case 'seed'
                    case 'none'
                end
                obj.displayMapOverlay();
            end
        end%overlayChoiceCb
        %%
        function onScrollCb(obj, ~, arg2, maxPosValue)
            obj.onScrollCb@imSeriesUI([], arg2, maxPosValue);
            switch getFeatureType(obj)
                case 'kMean_STRG'
                    obj.dispResultskMeanStgr();
                otherwise
                    obj.displayMapOverlay();
            end
        end%maxPosValue
        %%
        function featNumberChoiceCb(obj, ~, ~)
            for k = 1 : 8
                if k > obj.getFeatNumber()
                    set(obj.dimChoiceUIStructTab.textUITab(k), 'visible', 'off');
                    set(obj.dimChoiceUIStructTab.popupUITab(k), 'visible', 'off');
                else
                    set(obj.dimChoiceUIStructTab.textUITab(k), 'visible', 'on');
                    set(obj.dimChoiceUIStructTab.popupUITab(k), 'visible', 'on');
                end
            end
        end%featNumberChoiceCb
        %%
        function obj = browsePatientPathCb(obj, arg1, arg2)
            obj = obj.browsePatientPathCb@baseUI();
            obj.updateSavePath('featuresDisplay');
        end%browseSavePathCb
        %%
        function [x, y] = onImgClick(obj, arg1, arg2, slcName)
            [x, y] = obj.onImgClick@imSeriesUI(arg1, arg2, slcName);
            switch obj.maskEditMode;
                case 'none'
                    slcSerie = obj.featTool.getSlcSerieMap(slcName);
                    mask = obj.getOverlay(slcName);
                    [xSeed, ySeed] = ind2sub(size(mask), find(mask == 1, 1, 'first'));
                    %figureMgr.getInstance.newFig(sprintf('tic_%s', slcName)); clf;
                    axes(obj.handleAxesTab(4)); cla;
                    hold all;
                    lgdKS = {};
                    %seedTic
                    seedTic = squeeze(slcSerie(xSeed, ySeed, :));
                    mask(mask > obj.getMaxOverlayValue(slcName)) = 0;
                    [rAvgTic, ~, ~] = obj.featTool.proccessRoiAvgTic(slcName, mask);
                    plot(seedTic, 'b'); lgdKS = [lgdKS 'seed'];
                    seedTic = seedTic(obj.featTool.getLwTCrop() : obj.featTool.getUpTCrop());
                    threshVal = obj.getMaxOverlayValue(slcName);
                    lwThreshTic = seedTic - threshVal; lwThreshTic(lwThreshTic < 0) = 0;
                    upThreshTic = seedTic + threshVal;
                    fillPlot((obj.featTool.getLwTCrop() : obj.featTool.getUpTCrop())', lwThreshTic, upThreshTic);
                    lgdKS = [lgdKS 'threshold bounds'];
                    %user clicked tic
                    plot(squeeze(slcSerie(x, y, :)), 'color', ones(1, 3) * 0.25); lgdKS = [lgdKS 'clicked'];
                    
                    plot(rAvgTic, '-', 'color', [0 0.5 0]); lgdKS = [lgdKS 'roi avg TIC'];
                    hl = legend(lgdKS);
                    
                    %axis tick
                    set(obj.handleAxesTab(4), 'xtick', [0 length(rAvgTic)], 'xticklabel', [0 length(rAvgTic)]);
                    set(obj.handleAxesTab(4), 'ytick', [0 round(max(upThreshTic))], 'yticklabel', [0 round(max(upThreshTic))]);
                    set(obj.handleAxesTab(4), 'XMinorTick', 'on', 'YMinorTick', 'on')
                    set(obj.handleAxesTab(4), 'XColor', [1 1 1]);
                    set(obj.handleAxesTab(4), 'YColor', [1 1 1]);
                    set(obj.handleAxesTab(4), 'color', [0 0 0]);
                    
                    %legend
                    set(hl, 'textColor', 'w');
                    set(hl, 'fontsize', 8);
                    set(hl, 'location', 'northwest');
                otherwise
                    opt.slcName = slcName;
                    obj.startMaskEditCb(obj.getOverlay(slcName), opt);
            end
        end
        %%
        function sldrCb(obj, src, ~, paramName)
            obj.sldrCb@sliderListUI([], [], paramName);
            obj.displayMapOverlay();
        end%sldrCb
        %%
        function eboxCb(obj, ~, ~, paramName)
            obj.eboxCb@sliderListUI([], [], paramName);
            obj.displayMapOverlay();
        end  
        %% other
        %%
        function obj = dispResults(obj)
            slcKS = obj.featTool.getSliceKS();
            switch getFeatureType(obj)
                case 'dynamic_thresh_roi_growing'
                   obj.dispResultsThreshEvolution();
                case 'kMean_STRG'
                     obj.dispResultskMeanStgr();
                case 'patient_reference'
                    obj.dispResultsPatientRef();
                case 'patient_voxels_Features'
                    c = {'*r', '*g', '*b'};
                    for k = 1 : length(slcKS)
%                         featureTab = obj.featTool.getSlcFeatureTab(char(slcKS(k)));
                        opt.c = char(c(k));
                        opt.figName = sprintf('featuresSpace_%s', char(slcKS(k)));
                        displayFeaturesSpace(obj.featTool.getSlcFeatures(char(slcKS(k))', obj.dimKS), obj.dimKS, opt);
                    end
                case 'homogeneousFeaturesRois'
                    obj.disResultsHomogeneousFeaturesRoi();
            end%switch
        end%dispResults
        %%
        function dispResultsPatientRef(obj)
            slcKS = obj.featTool.getSliceKS();
            tGroup = uitabgroup('Parent', obj.rPanel);
            set(tGroup, 'BackgroundColor', 'black');
            tab1 = uitab('Parent', tGroup, 'Title', 'Overlay');
            obj.handleAxesTab = tight_subplot(3, 2, [.01 .01], [.05 .05], [.01 .01], tab1);
            tab2 = uitab('Parent', tGroup, 'Title', 'features space');
            ftAxisHdle = tight_subplot(1, 1, [.01 .01], [.25 .1], [.15 .15], tab2);
            
            
            %axes color
            set(obj.handleAxesTab, 'color', [0 0 0]);
            set(obj.handleAxesTab, 'XColor', [1 1 1]);
            set(obj.handleAxesTab, 'YColor', [1 1 1]);
            for k = 1 : length(slcKS)
                %slice peak image
                axes(obj.handleAxesTab(2 * (k - 1) + 1));
                slcSerie = obj.featTool.getSlcSerieMap(char(slcKS(k)));
                imagesc(obj.overlayImg(obj.correctImage(slcSerie(:, :, 25)), obj.featTool.getLesionMask(char(slcKS(k))), obj.featTool.getNormalMask(char(slcKS(k)))));
                axis off image;
                
%                 obj.optimizeFocus(obj.handleAxesTab(2 * (k - 1) + 1),...
%                     obj.featTool.getLesionMask(char(slcKS(k))) + obj.featTool.getNormalMask(char(slcKS(k))));
                %time intensity curves
                axes(obj.handleAxesTab(2 * k)); hold on;
                opt.style = obj.getPtStyle(char(slcKS(k)));
                try
                    plot(obj.featTool.getRoiAvgTic(char(slcKS(k)), 'normal'), 'color', [0 .5 0], 'linestyle', opt.style); 
                    axis ; grid on; %set(gca,'xticklabel');
                    xlabel('time (heartbeat)', 'fontSize', 10); ylabel('intensity (A.U)');
                catch
                    cprintf('orange', 'no average tic for slice %s, class normal', char(slcKS(k)));
                end
                try
                    plot(obj.featTool.getRoiAvgTic(char(slcKS(k)), 'lesion'), [opt.style 'r']);
                    axis; grid on; %set(gca,'xticklabel');
                     xlabel('time (heartbeat)'); ylabel('intensity (A.U)');
                catch
                    cprintf('orange', 'no average tic for slice %s, class lesion', char(slcKS(k)));
                end
                
                
                %features space
                opt.axisHdle = ftAxisHdle;
                opt.color = [0 .5 0];
                displayFeaturesSpace((obj.featTool.getRoiFeatures(char(slcKS(k)),...
                    'normal', obj.dimKS))', obj.dimKS, opt);
                opt.color = 'r'; 
                displayFeaturesSpace((obj.featTool.getRoiFeatures(char(slcKS(k)),...
                    'lesion', obj.dimKS))', obj.dimKS, opt);
            end
            set(ftAxisHdle, 'color', [0 0 0]);
            set(ftAxisHdle, 'XColor', [1 1 1]);
            set(ftAxisHdle, 'YColor', [1 1 1]);
            set(ftAxisHdle, 'ZColor', [1 1 1]);
        end%dispResultsPatientRef
        %%
        function ptStyle = getPtStyle(obj, sliceName)
            switch sliceName
                case 'apex'
                    ptStyle = 'v';
                case 'mid'
                    ptStyle = 'o';
                case 'base'
                    ptStyle = '*';
                otherwise
            end%switch
        end%getPtStyle
        %%
        function dispResultsThreshEvolution(obj)
            tGroup = uitabgroup('Parent', obj.rPanel);
            set(tGroup, 'BackgroundColor', 'black');
            tab1 = uitab('Parent', tGroup, 'Title', 'Overlay');
            obj.isPanelHdleParent = tab1;
            tab2 = uitab('Parent', tGroup, 'Title', 'Gradients');
            gdtHdleAxesTab = tight_subplot(3, 1, [.15 .05], [.15 .05], [.2 .05], tab2);
            tab3 = uitab('Parent', tGroup, 'Title', 'features space');
            ftSpceHdleAxesTab = tight_subplot(2, 2, [.15 .15], [.1 .05], [.1 .01], tab3); 
            
            %features space
            slcKS = obj.featTool.getSliceKS();
            c = {'m', 'c', 'y'};%slice
            for k = 1 : length(slcKS)
                opt.color = char(c(k));
                opt.style = '-';
                opt.figName = sprintf('featuresSpace_%s', char(slcKS(k)));
                opt.slcName = char(slcKS(k));
                opt.rootPath = fullfile(obj.getPatientPath(), 'featuresDisplay');
                opt.axisHdle = ftSpceHdleAxesTab(k);
                %threshold average TIC features
                featureTab = obj.featTool.getSlcNormalizedThreshRoiFeaturesTab(char(slcKS(k)));
                displayFeaturesSpace(featureTab', obj.dimKS, opt);
                set(ftSpceHdleAxesTab(k), 'XColor', [1 1 1]);
                set(ftSpceHdleAxesTab(k), 'YColor', [1 1 1]);
                set(ftSpceHdleAxesTab(k), 'ZColor', [1 1 1]);
                set(ftSpceHdleAxesTab(k), 'color', [0 0 0]);
                
                
                % get absolute surface of first ROI to regulate initial
                % vector
                
                %roiSurfVect = obj.featTool.getSlcThreshRoiSurfaceVect(opt);
                
                %gradients features of threshold average TIC features
                featureTabGradients = obj.featTool.getSlcThreshRoiNormalizedFeaturesGradientsTab(char(slcKS(k)));
                %thresholdVect = obj.featTool.getSlcFeatures(char(slcKS(k)), {'treshold'});
%                 figureMgr.getInstance.newFig('gradients'); hold all;
                axes(gdtHdleAxesTab(k));
%                 subplot(3, 1, k); hold all; title(char(slcKS(k)))
                plot(featureTabGradients); hold all; title(char(slcKS(k)))
                set(gdtHdleAxesTab(k), 'XColor', [1 1 1]);
                set(gdtHdleAxesTab(k), 'YColor', [1 1 1]);
                set(gdtHdleAxesTab(k), 'color', [0 0 0]);
                
                %gradient norm
                featuresGradientsNorm =  obj.featTool.getSlcThreshRoiNormalizedFeaturesGradientsNorm(char(slcKS(k)));
                plot(featuresGradientsNorm); xlabel('K'); ylabel('features variation');
                
                if max(featuresGradientsNorm(:)) > 0.3
                    ylim([-0.1 max(featuresGradientsNorm(:))]);
                else
                    ylim([-0.1 0.3]);
                end
                xlim([0 35]);
                hl = legend([obj.dimKS 'gradientNorm']);
                set(hl, 'textColor', 'w');
                %maxPos = find(featuresGradientsNorm > 0.75 * max(featuresGradientsNorm), 1, 'first');
                optThresh = obj.featTool.getOptThreshVal(char(slcKS(k)));
                plot(optThresh, featuresGradientsNorm(optThresh), 'or');
                
                continue;
                %voxels' tic features
                slcFeatureTab = obj.featTool.getSlcNormalizedFeatures(char(slcKS(k)), obj.dimKS);
                opt.style = '*';
                cMap = colormap(jet(max(thresholdVect)));
                for l = 1 : length(thresholdVect)
                    opt.color = cMap(thresholdVect(l), :);
                    handle = displayFeaturesSpace(slcFeatureTab(:,l), obj.dimKS, opt);
                    %dcm_obj = datacursormode(handle);
                    %set(dcm_obj, 'UpdateFcn', {@updateDatatipFeatDisplayCb, obj.dimKS, slcFeatureTab(:,l), thresholdVect(l)});
                end
            end
            set(ftSpceHdleAxesTab(4), 'color', [0 0 0]);
            %images series
            obj.updateOverlayControls();
            obj.displayMapOverlay(tab1);
        end%dispResultsThreshEvolution
        
        function dispResultskMeanStgr(obj)
            tGroup = uitabgroup('Parent', obj.rPanel);
            set(tGroup, 'BackgroundColor', 'black');
            tab1 = uitab('Parent', tGroup, 'Title', 'Overlay');
            obj.isPanelHdleParent = tab1;
            obj.handleAxesTab = tight_subplot(2, 2, [.01 .01], [.01 .01], [.1 .01], obj.isPanelHdleParent);
            slcKS = obj.featTool.getSliceKS();
            
            for k = 1 : length(slcKS)
                slcName = char(slcKS(k));
                strgMask = obj.featTool.getStrgMask(slcName);
                kMeanMask = obj.featTool.getKMeanLesionRoiMaskMap(slcName);
                slcSerie = obj.featTool.getSlcSerieMap(slcName);
                axes(obj.handleAxesTab(k));
                h = imagesc(overlay(obj.correctImage(slcSerie(:, :, obj.slcTimePos)), strgMask));
                
                bnds = obj.processMaskBounds(imdilate(kMeanMask, strel('disk', 1)));
                for m = 1 : length(bnds)
                    obj.boundariesPlot(bnds{m}, 'c', obj.handleAxesTab(k), 2);
                end
                set(h, 'ButtonDownFcn', {@obj.onImgClick, slcName});
                axis off image;
                obj.optimizeFocus(obj.handleAxesTab(k), obj.featTool.getMyoMask(slcName));
                obj.displayMyoBoundaries(slcName, obj.handleAxesTab(k));
                text('units', 'normalized', 'position', [0.5, 0.05], 'fontsize', 10,...
                    'color', 'white', 'string', ...
                    sprintf('%s, %d/%d', slcName, obj.slcTimePos, size(slcSerie, 3)));
                set(gcf, 'WindowScrollWheelFcn', {@obj.onScrollCb, size(slcSerie, 3)});
                
            end
            
        end
        
        %%
        function dispResultskMeanSTRG(obj)
            tGroup = uitabgroup('Parent', obj.rPanel);
            set(tGroup, 'BackgroundColor', 'black');
            tab1 = uitab('Parent', tGroup, 'Title', 'Overlay');
            obj.isPanelHdleParent = tab1;
            obj.displayMapOverlay(tab1);
        end%dispResultskMeanSTRG
        %%
        function disResultsHomogeneousFeaturesRoi(obj)
            obj.updateOverlayControls();
            obj.displayMapOverlay();
        end%disResultsRoiFeatures
        %%
        function displayMapOverlay(obj, parent)
            slcKS = obj.featTool.getSliceKS();
            if isempty(obj.handleAxesTab)
                obj.handleAxesTab = tight_subplot(2, 2, [.01 .01], [.01 .01], [.1 .01], obj.isPanelHdleParent);
                %reduce axis size of plot axis
                pos = get(obj.handleAxesTab(4), 'pos');
                set(obj.handleAxesTab(4), 'pos', [(pos(1) + 0.1 * pos(1)) (pos(2) +  0.1 *pos(4)) (pos(3) * 0.85) (pos(4) * 0.85)]);
                 set(obj.handleAxesTab(4), 'color', 'k');
            end
            for k = 1 : length(slcKS)
                slcName = char(slcKS(k));
                mask = obj.getOverlay(slcName);
                mask(mask > obj.getMaxOverlayValue(slcName)) = 0;
                slcSerie = obj.featTool.getSlcSerieMap(slcName);
                axes(obj.handleAxesTab(k));
                h = imagesc(overlay(obj.correctImage(slcSerie(:, :, obj.slcTimePos)), mask));
                set(h, 'ButtonDownFcn', {@obj.onImgClick, slcName});
                axis off image;
                obj.optimizeFocus(obj.handleAxesTab(k), obj.featTool.getMyoMask(slcName));
                obj.displayMyoBoundaries(slcName, obj.handleAxesTab(k));
                obj.displayRoiBoundaries(slcName, obj.handleAxesTab(k));
                text('units', 'normalized', 'position', [0.5, 0.05], 'fontsize', 10,...
                    'color', 'white', 'string', ...
                    sprintf('%s, %d/%d', slcName, obj.slcTimePos, size(slcSerie, 3)));
                set(gcf, 'WindowScrollWheelFcn', {@obj.onScrollCb, size(slcSerie, 3)});
            end
        end%displayMap
        %%
        function displayMyoBoundaries(obj, slcName, axisHdle)
            if nargin == 2
                axisHdle = gca;
            end
            bnds = obj.processMaskBounds(obj.featTool.getMyoMask(slcName));
            obj.boundariesPlot(bnds{1}, [1 0 0], axisHdle, 2);
            obj.boundariesPlot(bnds{2}, [0 1 0], axisHdle, 2);
        end%displayMyoBoundaries
        %%
        function displayRoiBoundaries(obj, slcName, axisHdle)
            mask = obj.featTool.getfirstRoiMask(slcName);
            mask(mask > obj.getMaxOverlayValue(slcName)) = 0;
            bnds = obj.processMaskBounds(imdilate(mask, strel('disk', 1)));
            for k = 1 : length(bnds)
                obj.boundariesPlot(bnds{k}, [0 0 1], axisHdle, 1);
            end
        end%displayRoiBoundaries
        %%
        function overlay = getOverlay(obj, slcName)
            switch obj.getOverlayType()
                case 'firstRoiMap'
                    overlay = obj.featTool.getfirstRoiMask(slcName);
                case 'seed'
                    overlay = obj.featTool.getSeedMask(slcName);
%                     overlay(overlay > 1) = 0;
                case 'AUCMask'
                    overlay = obj.featTool.getAUCMask(slcName);
                case 'roisMap'
                    overlay = obj.featTool.getRoisMask(slcName);
                case 'threshold'
                    overlay = obj.featTool.getThreshRoisMask(slcName);
                case 'none'
                    overlay = obj.featTool.getfirstRoiMask(slcName);
                    overlay(:) = 0;
            end
        end
        %%
        function dimName = getDimensionName(obj, dimNum)
            dimList = get(obj.dimChoiceUIStructTab.popupUITab(dimNum), 'String');
            dimName = char(dimList(get(obj.dimChoiceUIStructTab.popupUITab(dimNum), 'Value')));
        end%getDimensionName
        %%
        function featParams = getFeatParams(obj)
            featParams.nbFeat = obj.getFeatNumber();
            for k = 1 : featParams.nbFeat
                featParams.(sprintf('feat%d', k)) = obj.getDimensionName(k);
            end
        end
        %%
        function featName = getFeatureType(obj)
            featList = get(obj.featuresTypeUIStruct.popupUI, 'String');
            featName = char(featList(get(obj.featuresTypeUIStruct.popupUI, 'Value')));
        end%getFeatureType
        %%
        function overlayType = getOverlayType(obj)
            choiceList = get( obj.overlayTypeUIStruct.popupUI, 'String');
            overlayType = char(choiceList (get(obj.overlayTypeUIStruct.popupUI, 'Value')));
        end
        %%
        function overlayIm = overlayImg(obj, im, lesionMask, normalMask)
            maxVal  = max(im(:));
            minVal  = min(im(:));
            rLayer = (im - minVal) / (maxVal - minVal);
            gLayer = rLayer;
            bLayer = rLayer;
            rLayer(normalMask == 1) = 0; gLayer(normalMask == 1) = 0.5; bLayer(normalMask == 1) = 0;
            rLayer(lesionMask == 1) = 1; gLayer(lesionMask == 1) = 0; bLayer(lesionMask == 1) = 0; 
            overlayIm = cat(3,rLayer, gLayer, bLayer);
        end%overlayImg
        %%
        function updateOverlayControls(obj)
            try
                slcKS = obj.featTool.getSliceKS();
                for k = 1 : length(slcKS)
                    slcName = char(slcKS(k));
                    mask = obj.getOverlay(slcName);
                    minVal = min(mask(mask > 0));
                    maxVal = max(mask(:));
                    obj.setSliderProperty(slcName, 'max', maxVal);
                    if  minVal < obj.getSldrValue(slcName) || maxVal > obj.getSldrValue(slcName)
                        obj.setSliderProperty(slcName, 'value', obj.featTool.getOptThreshVal(slcName));
                    end
                end
            catch e
                obj.lgr.warn('overlay not loaded yet');
            end
        end%updateOverlayControls
        %%
        function validKey = onKeyPressCb(obj, ~, arg)
            validKey = obj.onKeyPressCb@baseUI([], arg);
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
        end
        %% mask edit
        %%
        function [mask, x, y] = maskEditCb(obj, arg1, ~, opt)
            mask = obj.maskEditCb@maskOverlayBaseUI(arg1, [], opt);
            if ~isnan(mask)
                mask(mask > 0) = 1;
                oldMask = obj.featTool.getfirstRoiMask(opt.slcName);
                oldMask(oldMask > 0) = 1;
                maskDiff = abs(oldMask - mask);
                myoMask = obj.featTool.getMyoMask(opt.slcName);
                myoMask(maskDiff == 1) = 0;
                obj.featTool.updateMyoMask(opt.slcName, myoMask);
                obj.featTool.updatemaskMaps(opt.slcName, mask);
            end
            axes(gca);
            imagesc(mask);
            axis off image;
            obj.optimizeFocus(gca, obj.featTool.getfirstRoiMask(opt.slcName));
            %obj.displayMapOverlay();
        end
        %%
        function stopMaskEditCb(obj, ~, ~, opt)
            obj.stopMaskEditCb@maskOverlayBaseUI();
            obj.displayMapOverlay();
        end%stopMaskEdit
    end%methods (Access = protected)
    
end

