classdef segSimilarityUI < imSeriesUI & maskOverlayBaseUI
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access = protected)
        segTypeUIStruct;
        similarityTool;
        obj
    end
    
    %% public static method
    methods (Static)
        function obj = getInstance()
            persistent localObj;
            %which isvalid
            if isempty(localObj) %|| ~isvalid(localObj)
                localObj = segSimilarityUI;
            end
            obj = localObj;
        end
    end%methods (Static)

    methods (Access = public)
        %%
        function obj = initialize(obj, hParent, pluginInfo, opt)
            obj.boundsDisplayMode = 'on';
            obj = obj.initialize@imSeriesUI(hParent, pluginInfo, opt);
            obj = obj.initPatientPathUI(fullfile(obj.basePath, 'patientData', 'patientName', 'example'));
            obj = obj.initMaskTypeUI();
        end%initialize
        %% getters
        %%
        function maskType = getMaskType(obj)
            isList = get(obj.segTypeUIStruct.popupUI, 'String');
            maskType = char(isList(get(obj.segTypeUIStruct.popupUI, 'Value')));
        end%getVisibleImSerie
        
    end%methods (Access = public)
    
    methods (Access = protected)
        %%
        function obj = initMaskTypeUI(obj)
            obj.segTypeUIStruct.textUI = ...
                uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(1) obj.lin(9) 0.1 0.05],...
                'String', 'mask');
            obj.segTypeUIStruct.popupUI = ...
                uicontrol(obj.lPanel, 'Style', 'popup',...
                'Units',  'normalized',...
                'Position', [obj.col(2) obj.lin(9) 0.4 obj.HdleHeight],...
                'String', {'kMean', 'strg'});
            %                 set(obj.dimChoiceUIStructTab.popupUITab(k), 'value', k);
        end%initDimensionUI
        %%
        function goCb(obj, ~, ~)
            clc
            obj.wipeResults();
            obj.setFooterStr('starting run');
            try
                obj.similarityTool = segSimilarityTool();
                opt.dataPath = obj.getDataPath();
                obj.similarityTool = obj.similarityTool.prepare(opt);
                obj.similarityTool = obj.similarityTool.run();
                obj.dispResults();
            catch e
                obj.setFooterStr('something bad happened x_x');
                rethrow(e);
            end
            obj.setFooterStr('run completed successfully');
        end%goCb(obj)
        %%
        function saveCb(obj)
        end%saveCb(obj)
        %%
        function dispResults(obj)
            if isempty(obj.handleAxesTab)
                obj.handleAxesTab = tight_subplot(2, 2, [.05 .05], [.05 .05], [.1 .01], obj.rPanel);
                set(obj.handleAxesTab(4), 'color', 'k');
            end
             isKS = obj.similarityTool.getSeriesKS(); %im series names
             for k = 1 : length(isKS)
                 isName = char(isKS(k));
                 axes(obj.handleAxesTab(k));
                 slcSerie = obj.similarityTool.getImserie(isName);
                 imagesc(obj.correctImage(slcSerie(:, :, obj.slcTimePos)));
                 colormap gray; axis off image;
                 obj.optimizeFocus(obj.handleAxesTab(k), obj.similarityTool.getMyoMask(isName));
                 hold on;
                 obj.displayMyoBoundaries(isName, obj.handleAxesTab(k));
                 obj.displayMaskBoundaries(obj.similarityTool.getGndTruthMask(isName), [.02 .66 .49], obj.handleAxesTab(k));
                 obj.displayMaskBoundaries(obj.similarityTool.getSegmentationMask(isName, obj.getMaskType()), [1 0 0], obj.handleAxesTab(k));
                 text('units', 'normalized', 'position', [0.1, 0.95], 'fontsize', 8,...
                     'color', [.02 .66 .49], 'string', 'expert');
                 text('units', 'normalized', 'position', [0.1, 0.9], 'fontsize', 8,...
                     'color', [1 0 0], 'string', obj.getMaskType());
                 text('units', 'normalized', 'position', [0.1, 0.05], 'fontsize', 8,...
                    'color', 'white', 'string', ...
                    sprintf('%s, %d/%d (dice index: %0.2f / hdd: %0.2f / inclusion: %0.2f)',...
                    isName, obj.slcTimePos, size(slcSerie, 3),...
                    obj.similarityTool.getDiceCoeff(isName, obj.getMaskType()), ...
                    obj.similarityTool.getHaussdorfDist(isName, obj.getMaskType()), ...
                    obj.similarityTool.getInclusionCoeff(isName, obj.getMaskType())));
                
                set(gcf, 'WindowScrollWheelFcn', {@obj.onScrollCb, size(slcSerie, 3)});
             end
             fprintf('%d/%d\n', obj.slcTimePos, size(slcSerie, 3));
%              legend('ground truth', 'segmentation')
        end%dispResults
        %%
        function displayMaskBoundaries(obj, mask, cmap, axisHdle)
            if nargin == 2
                axisHdle = gca;
            end
            bnds = obj.processMaskBounds(mask);
            for m = 1 : length(bnds)
                obj.boundariesPlot(bnds{m}, cmap, axisHdle, 1);
            end
        end
        
        function displayMyoBoundaries(obj, slcName, axisHdle)
            if nargin == 2
                axisHdle = gca;
            end
            bnds = obj.processMaskBounds(obj.similarityTool.getMyoMask(slcName));
            obj.boundariesPlot(bnds{2}, [1 0 0], axisHdle, 2);
            obj.boundariesPlot(bnds{1}, [0 1 0], axisHdle, 2);
        end%displayMyoBoundaries
        
        %%
        function onScrollCb(obj, ~, arg2, maxPosValue)
            obj.onScrollCb@imSeriesUI([], arg2, maxPosValue);
            obj.dispResults();
        end
        %%
        function validKey = onKeyPressCb(obj, ~, arg)
            validKey = obj.onKeyPressCb@baseUI([], arg);
            if validKey
                obj.dispResults();
                return;
            end
            prevMode = obj.maskEditMode;
            validKey = obj.onKeyPressCb@maskOverlayBaseUI([], arg);
            if strcmp('none', obj.maskEditMode) && ...
                    (strcmp('eraser', prevMode) || strcmp('pencil', prevMode))
                obj.featTool.saveMyoMaskUpdate();
            end
        end
    end%methods (Access = protected)
    
end

