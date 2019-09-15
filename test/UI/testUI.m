classdef testUI < imSeriesUI & maskOverlayBaseUI
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access = protected)
        imgSeriesTool;
        obj
    end
    
    %% public static method
    methods (Static)
        function obj = getInstance()
            persistent localObj;
            %which isvalid
            if isempty(localObj) %|| ~isvalid(localObj)
                localObj = testUI;
            end
            obj = localObj;
        end
    end%methods (Static)

    methods (Access = public)
        %%
        function obj = initialize(obj, hParent, pluginInfo, opt)
            obj = obj.initialize@imSeriesUI(hParent, pluginInfo, opt);
            obj = obj.initPatientPathUI(fullfile(obj.basePath, 'patientData', 'patientName', 'example'));
        end%initialize
        %%
        
    end%methods (Access = public)
    
    methods (Access = protected)
        %%
        function goCb(obj, ~, ~)
            clc
            obj.wipeResults();
            obj.setFooterStr('starting run');
            try
                obj.imgSeriesTool = testTool();
                opt.dataPath = obj.getDataPath();
                obj.imgSeriesTool = obj.imgSeriesTool.prepare(opt);
                obj.imgSeriesTool = obj.imgSeriesTool.run();
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
             isKS = obj.imgSeriesTool.getSeriesKS(); %im series names
             for k = 1 : length(isKS)
                 isName = char(isKS(k));
                 axes(obj.handleAxesTab(k));
                 slcSerie = obj.imgSeriesTool.getImserie(isName);
                 imagesc(obj.correctImage(slcSerie(:, :, obj.slcTimePos)));
                 colormap gray; axis off image;
                 obj.optimizeFocus(obj.handleAxesTab(k), obj.imgSeriesTool.getMyoMask(isName));
                 text('units', 'normalized', 'position', [0.5, 0.05], 'fontsize', 10,...
                    'color', 'white', 'string', ...
                    sprintf('%s, %d/%d', isName, obj.slcTimePos, size(slcSerie, 3)));
                set(gcf, 'WindowScrollWheelFcn', {@obj.onScrollCb, size(slcSerie, 3)});
             end
        end%dispResults
        %%
        function onScrollCb(obj, ~, arg2, maxPosValue)
            obj.onScrollCb@imSeriesUI([], arg2, maxPosValue);
            obj.dispResults();
        end
    end%methods (Access = protected)
    
end

