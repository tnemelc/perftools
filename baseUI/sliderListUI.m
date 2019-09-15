classdef sliderListUI < baseUI
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        slrData; % slider data
        sldrGrid;
        sldrHdleHeight;
    end
    
    methods (Access = public)
        %%
        function obj = initSldrParameters(obj)
            obj.lgr.warn('this function is an example and shall not be modified but overloaded in inherited classes');
            obj.slrData.keySet =     {'param1', 'param2',  'param3'}; % append set name here
            obj.slrData.initValSet = {   8,         65,       10   }; %append new param init value
            obj.slrData.minValSet =  {   1,         50,        1   }; %append new param min value
            obj.slrData.maxValSet =  { 100,        150,       20   };%append new param max value
            obj.slrData.factorSet =  {1e-3,       1e-3,     1e-2   };%append new factor value (1 if no need to factor)
            obj.slrData.unitSet =    {'cc/s/g', 'cc/s/g',  'cc/g'  };%append unit string
            
            obj.initParamLayoutStructure(0.9, 0.2);
            obj.initParametersMaps();
            obj.dispParamSldr();
        end%initParametersMap
        
        function obj = initParamLayoutStructure(obj, upperHeight, lowerHeight)
            nbHdles = length(obj.slrData.keySet) + 3;
            nbHdles = length(obj.slrData.keySet) + 3;
            obj.sldrHdleHeight =  (upperHeight - lowerHeight) * 0.9 / nbHdles;
            obj.sldrGrid.lin = upperHeight : -obj.sldrHdleHeight : lowerHeight;
            obj.sldrGrid.col = 0.1 : 0.1 : 0.9;
        end%initParamLayoutStructure
        
        function obj = initParametersMaps(obj)
            obj.slrData.valMap = containers.Map(obj.slrData.keySet, obj.slrData.initValSet);
            obj.slrData.minValMap = containers.Map(obj.slrData.keySet, obj.slrData.minValSet);
            obj.slrData.maxValMap = containers.Map(obj.slrData.keySet, obj.slrData.maxValSet);
            obj.slrData.paramTextMap = containers.Map(obj.slrData.keySet, obj.slrData.initValSet);
            obj.slrData.editBoxMap = containers.Map(obj.slrData.keySet, obj.slrData.initValSet);
            obj.slrData.sldrMap = containers.Map(obj.slrData.keySet, obj.slrData.initValSet);
            obj.slrData.unitTextMap = containers.Map(obj.slrData.keySet, obj.slrData.initValSet);
            obj.slrData.factorMap = containers.Map(obj.slrData.keySet, obj.slrData.factorSet);
        end%createParametersMaps
        
        %%
        function obj = dispParamSldr(obj)
            hdleHeight = obj.sldrHdleHeight * 0.9;
            for i = 1 : size(obj.slrData.keySet, 2)
                %set real value for val map
                obj.slrData.valMap(char(obj.slrData.keySet(i))) = obj.slrData.valMap(char(obj.slrData.keySet(i))) * obj.slrData.factorMap(char(obj.slrData.keySet(i)));
                % text
                hPos = obj.sldrGrid.lin(i + 2);
                obj.slrData.paramTextMap(char(obj.slrData.keySet(i))) = ...
                    uicontrol(obj.lPanel, 'Style', 'text',...
                    'Units',  'normalized',...
                    'Position', [obj.sldrGrid.col(1) hPos 0.1 hdleHeight],...
                    'String', obj.slrData.keySet(i));
                
                %slider
                obj.slrData.sldrMap(char(obj.slrData.keySet(i))) = ...
                    uicontrol(obj.lPanel, 'Style', 'slider',...
                    'Units',  'normalized',...
                    'Value', obj.slrData.valMap(char(obj.slrData.keySet(i))) / obj.slrData.factorMap(char(obj.slrData.keySet(i))),...
                    'Min',obj.slrData.minValMap(char(obj.slrData.keySet(i))), ...
                    'Max',obj.slrData.maxValMap(char(obj.slrData.keySet(i))), ...
                    'Position', [obj.sldrGrid.col(2) hPos 0.35 hdleHeight],...
                    'Callback', {@obj.sldrCb, obj.slrData.keySet(i)});
                
                %edit box
                obj.slrData.editBoxMap(char(obj.slrData.keySet(i))) = ...
                    uicontrol(obj.lPanel, 'Style', 'edit',...
                    'Units',  'normalized',...
                    'String', obj.slrData.valMap(char(obj.slrData.keySet(i))),...
                    'Position', [obj.sldrGrid.col(6) hPos 0.1 hdleHeight], ...
                    'Callback', {@obj.eboxCb, obj.slrData.keySet(i)});
                
                % units
               
                obj.slrData.unitTextMap(char(obj.slrData.keySet(i))) = ...
                    uicontrol(obj.lPanel, 'Style', 'text',...
                    'Units',  'normalized',...
                    'Position', [obj.sldrGrid.col(8) hPos 0.1 hdleHeight],...
                    'String', obj.slrData.unitSet(i));
            end
            
            
        end%dispSldrSet
        %% getters
        %% 
        function val = getSldrValue(obj, paramName)
            val = obj.slrData.valMap(paramName);
        end%getSldrValue
        %%
        function valStruct = getSldrValueList(obj)
            for k = 1 : obj.slrData.sldrMap.length
                valStruct.(char(obj.slrData.keySet(k))) = obj.slrData.valMap(char(obj.slrData.keySet(k)));
            end
        end%getSldrValueList
        %% setters
        %%
        function setSliderProperty(obj, paramName, name, value)
            set(obj.slrData.sldrMap(paramName), name, value);
            if strcmp(name, 'value')
                set(obj.slrData.editBoxMap(paramName), 'string', num2str(value));
                obj.slrData.valMap(paramName) = value;
            end
        end%setSliderProperty
       
        
    end% methods (Acces = public)
    
    methods (Access = protected)
        %%
        function sldrCb(obj, ~, ~, paramName)
            val  =  floor(get(obj.slrData.sldrMap(char(paramName)), 'Value')) * obj.slrData.factorMap(char(paramName));
            obj.slrData.valMap(char(paramName)) = val;
            set(obj.slrData.editBoxMap(char(paramName)), 'String', num2str(val));
        end
        %%
        function eboxCb(obj, ~, ~, paramName)
            val  =  str2num(get(obj.slrData.editBoxMap(char(paramName)), 'String'));
            %str = char(cell(floor(get(source, 'Value'))));
            %nbPE  = str2num(str);
            obj.slrData.valMap(char(paramName)) = val;
            set(obj.slrData.sldrMap(char(paramName)), 'Value', obj.slrData.valMap(char(paramName)) / obj.slrData.factorMap(char(paramName)));
        end
    end%methods (Access = protected)
end

