classdef exampleUI < sliderListUI
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        x;
        y;
    end
    
    %% public static method
    methods (Static)
        function obj = getInstance()
            persistent localObj;
            %which isvalid
            if isempty(localObj) %|| ~isvalid(localObj)
                localObj = exampleUI;
            end
            obj = localObj;
        end
    end%methods (Static)

    methods (Access = public)
        %%
        function obj = initialize(obj, hParent, pluginInfo, opt)
            obj = obj.initialize@baseUI(hParent, pluginInfo, opt);
            obj = obj.initPatientPathUI(fullfile(obj.basePath, 'patientData', 'patientName', 'example'));
            obj.initSldrParameters();
        end%initialize
        %%
        
    end%methods (Access = public)
    
    methods (Access = protected)
        %%
        function goCb(obj, ~, ~)
            obj.wipeResults();
            obj.dispResults();
        end%goCb(obj)
        %%
        function saveCb(obj)
        end%saveCb(obj)
        %%
        function dispResults(obj)
             obj.handleAxesTab = tight_subplot(2, 2, [.1 .1], [.05 .05], [.1 .01], obj.rPanel);
             axes(obj.handleAxesTab(1));
             plot((1:10) * obj.getSldrValue('param1'));
             axes(obj.handleAxesTab(2));
             plot((1:10) * obj.getSldrValue('param2'));
             axes(obj.handleAxesTab(3));
             plot((1:10) * obj.getSldrValue('param3'));
             axes(obj.handleAxesTab(3));
             plot((1:10)* obj.getSldrValue('param3') + obj.getSldrValue('param1'));
             
        end%dispResults
        
    end%methods (Access = protected)
    
end

