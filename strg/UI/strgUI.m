classdef strgUI < imSeriesUI & maskOverlayBaseUI & sliderListUI
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
                localObj = strgUI;
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
            obj = obj.initDataPathUI(fullfile(obj.basePath, 'patientData', 'patientName'));
            obj.initFeatNumber(3);
            obj.initDimensionUI();
            obj.initOverlayTypeUI();
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
                    'String', {'TTP', 'AUC', 'maxSlope', 'PeakVal', 'delay', 'maxSlopePos', 'TTPStd',  'AUCStd', 'maxSlopeStd', 'PeakValStd', 'roiSurface'});
                set(obj.dimChoiceUIStructTab.popupUITab(k), 'value', k);
                if k > obj.getFeatNumber()
                    set(obj.dimChoiceUIStructTab.textUITab(k), 'visible', 'off');
                    set(obj.dimChoiceUIStructTab.popupUITab(k), 'visible', 'off');
                end
            end
        end%initDimensionUI
        
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
            	obj.featTool = kMeanSTRGFeatTool();
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
            obj.setFooterStr('saving');
            savePath = obj.getSavePath(); 
            emptyDir(savePath);

            isKS = obj.featTool.getSliceKS();
            
            for k = 1 :  length(isKS)
                mkdir(fullfile(savePath, isKS{k}));
                kmeanMask = obj.featTool.getKMeanLesionRoiMask(isKS{k});
                savemat(fullfile(savePath, isKS{k}, 'kMeanMask'), kmeanMask);
                nbRois = max(kmeanMask(:));
                strgMask = zeros(size(kmeanMask));
                for m = 1 : nbRois
                    tmp = obj.featTool.getStrgMask(isKS{k}, m);
                    strgMask(tmp > 0) = m;
                    root.roisInfo.roi{m}.id = m;
                    root.roisInfo.roi{m}.name = sprintf('lesion%d', m);
                    [x, y] = ind2sub(size(tmp), find(tmp == 1, 1, 'first'));
                    root.roisInfo.roi{m}.seed.x = x;
                    root.roisInfo.roi{m}.seed.y = y;
                    root.roisInfo.roi{m}.thresh = max(tmp(:));
                end
                savemat(fullfile(savePath, isKS{k}, 'strgMask'), strgMask);
                savemat(fullfile(savePath, isKS{k}, 'myoMask'), obj.featTool.getMyoMask(isKS{k}));
                struct2xml(root, fullfile(savePath, ['roiInfo_' isKS{k} '.xml']));
                root = [];
            end
            obj.setFooterStr('saving completed successfully');
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
            obj.displayMapOverlay();
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
            obj.updateSavePath('strg');
        end%browseSavePathCb
        %%
        function [x, y] = onImgClick(obj, arg1, arg2, slcName)
            [x, y] = obj.onImgClick@imSeriesUI(arg1, arg2, slcName);
            switch obj.maskEditMode
                case 'none'
                    slcSerie = obj.featTool.getSlcSerieMap(slcName);
                    roiId = obj.featTool.getKMeansMaskRoId(slcName, x, y);
                    if roiId == 0
                        axes(obj.handleAxesTab(4));
                        hold on;
                        seedTic = squeeze(slcSerie(x, y, :));
                        plot(squeeze(slcSerie(x, y, :)), 'color', ones(1, 3) * 0.25); lgdKS = [lgdKS 'clicked'];
                        return;
                    end
                    mask = obj.featTool.getStrgMask(slcName, roiId);
                    [xSeed, ySeed] = ind2sub(size(mask), find(mask == 1, 1, 'first'));
                    %figureMgr.getInstance.newFig(sprintf('tic_%s', slcName)); clf;
                    axes(obj.handleAxesTab(4)); cla;
                    hold all;
                    lgdKS = {};
                    %seedTic
                    seedTic = squeeze(slcSerie(xSeed, ySeed, :));
                    %mask(mask > obj.getMaxOverlayValue(slcName)) = 0;
                    [rAvgTic, ~, ~] = obj.featTool.proccessRoiAvgTic(slcName, mask);
                    plot(seedTic, 'b'); lgdKS = [lgdKS 'seed'];
                    seedTic = seedTic(obj.featTool.getLwTCrop() : obj.featTool.getUpTCrop());
                    threshVal = max(mask(:));
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
            tGroup = uitabgroup('Parent', obj.rPanel);
            set(tGroup, 'BackgroundColor', 'black');
            tab1 = uitab('Parent', tGroup, 'Title', 'Overlay');
            obj.isPanelHdleParent = tab1;
            if isempty(obj.handleAxesTab)
                obj.handleAxesTab = tight_subplot(2, 2, [.01 .01], [.01 .01], [.1 .01], obj.isPanelHdleParent);
                set(obj.handleAxesTab(4), 'color', 'k');
            end
            obj.displayMapOverlay();
        end%dispResults     

        %%
        function displayMapOverlay(obj, parent)
            isKS = obj.featTool.getSliceKS();
            
            for k = 1 : length(isKS)
                isName = char(isKS(k));
                strgMask = obj.featTool.getStrgMask(isName);
%                 kMeanMask = obj.featTool.getKMeanLesionRoiMask(isName);
                slcSerie = obj.featTool.getSlcSerieMap(isName);
                axes(obj.handleAxesTab(k));
                switch obj.getOverlayType()
                    case 'firstRoiMap'
                        h = imagesc(overlay(obj.correctImage(slcSerie(:, :, obj.slcTimePos)), strgMask));
                    otherwise
                        h = imagesc(obj.correctImage(slcSerie(:, :, obj.slcTimePos)));
                end
                colormap gray; axis off image;
                obj.optimizeFocus(obj.handleAxesTab(k), obj.featTool.getMyoMask(isName));
                hold on
                obj.displayMyoBoundaries(isName, obj.handleAxesTab(k));
                obj.displayRoiBoundaries(isName, obj.handleAxesTab(k));
                
                text('units', 'normalized', 'position', [0.5, 0.05], 'fontsize', 10,...
                    'color', 'white', 'string', ...
                    sprintf('%s, %d/%d', isName, obj.slcTimePos, size(slcSerie, 3)));
                
               
                
                set(h, 'ButtonDownFcn', {@obj.onImgClick, isName});
                set(gcf, 'WindowScrollWheelFcn', {@obj.onScrollCb, size(slcSerie, 3)});
            end
        end%displayMap
        %%
        function displayMyoBoundaries(obj, slcName, axisHdle)
            if nargin == 2
                axisHdle = gca;
            end
            bnds = obj.processMaskBounds(obj.featTool.getMyoMask(slcName));
            obj.boundariesPlot(bnds{2}, [1 0 0], axisHdle, 2);
            obj.boundariesPlot(bnds{1}, [0 1 0], axisHdle, 2);
        end%displayMyoBoundaries
        %%
        function displayRoiBoundaries(obj, slcName, axisHdle)
            mask = obj.featTool.getKMeanLesionRoiMask(slcName);
            maxVal = max(mask(:));
            for k = 1 : maxVal
                tmp = mask;
                tmp(mask ~= k) = 0;
                tmp(mask == k) = 1;
                %             mask(mask > obj.getMaxOverlayValue(slcName)) = 0;
                bnds = obj.processMaskBounds(imdilate(tmp, strel('disk', 1)));
                for m = 1 : length(bnds)
                    obj.boundariesPlot(bnds{m}, 'c', axisHdle, 1);
                end
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
                return;
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
                obj.featTool.updateMaskMaps(opt.slcName, mask);
            end
            axes(gca);
            imagesc(mask);
            axis off image;
            obj.optimizeFocus(gca, obj.featTool.getMyoMask(opt.slcName));
            %obj.displayMapOverlay();
        end
        %%
        function stopMaskEditCb(obj, ~, ~, opt)
            obj.stopMaskEditCb@maskOverlayBaseUI();
            obj.displayMapOverlay();
        end%stopMaskEdit
    end%methods (Access = protected)
    
end

