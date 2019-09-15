classdef FantomeUI < baseUI
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    %% private properties
    properties (Access = private)
        paramTab;
        mdlChUI;% model listbox
        shapeUI; %phantom shape UI
        mapPathUI; %path to mbf & mbv maps (myocardium shape)
        aifPathUI;
        slrData;
        nbHdles;
        phtGentor;
    end
    events 
        modelChanged;
    end
    %% public static method
    methods (Static)
        function obj = getInstance()
            persistent localObj;
            %which isvalid;
            if isempty(localObj) %|| ~isvalid(localObj)
                localObj = FantomeUI;
            end
            obj = localObj;
        end
    end
    
    %% public methods
    methods (Access = public)
        function obj = initialize(obj, hParent, pluginInfo, opt)
            obj = obj.initialize@baseUI(hParent, pluginInfo, opt);
            %obj.setdefaultImage();
            obj = obj.initParametersMap('Fermi');
            obj = obj.setAifPathUI();
            obj = obj.setmodelChoiceUI();
            obj = obj.setShapeUI();
            obj = obj.setMbfMapPathUI();
            obj = obj.dispSldrSet();
            obj.updateSavePath(fullfile(obj.basePath, 'phantom\1_Myocarde'));
        end
        function obj = resetSliderDiplay(obj, model)
            for k = 1 : obj.slrData.sldrMap.length()
                delete( obj.slrData.paramTextMap(char(obj.slrData.keySet(k))));
                delete( obj.slrData.sldrMap(char(obj.slrData.keySet(k))));
                delete( obj.slrData.editBoxMap(char(obj.slrData.keySet(k))));
                delete( obj.slrData.unitTextMap(char(obj.slrData.keySet(k))));
            end
            obj = obj.initParametersMap(model);
            obj = obj.dispSldrSet();
        end
        
        % getters
        function model = getModelChoice(obj)
            modelList = get(obj.mdlChUI, 'String');
            modelVal = get(obj.mdlChUI, 'Value');
            model = char(modelList(modelVal));
        end
        
        function aifPath = getAifPath(obj)
            aifPath = get(obj.aifPathUI, 'String');
        end
        
        function savePath = getSavePath(obj)
            savePath = get(obj.savePathUI, 'String');
        end%getSavePath
        
        function params = getParameters(obj)
            for k = 1 : obj.slrData.sldrMap.length
                params.(char(obj.slrData.keySet(k))) = obj.slrData.valMap(char(obj.slrData.keySet(k)));
            end
            params.aifPath = obj.getAifPath();
            params.model = obj.getModelChoice();
            params.shape = obj.getShapeChoice();
            if strcmp(params.shape, 'myocardium')
              params.mbfMapPath = obj.getMapPath('mbfMap.mat');
              params.mbvMapPath = obj.getMapPath('mbvMap.mat');
            end
            
        end%getParameters
        
        function shapeChoice = getShapeChoice(obj)
            shapeChoiceList = get( obj.shapeUI, 'String');
            shapeChoice = char(shapeChoiceList(get( obj.shapeUI, 'Value')));
        end%getShapeChoice
        
        function mapPath = getMapPath(obj, mapName)
            mapPath = fullfile(get(obj.mapPathUI, 'string'), mapName);
        end%getMbfMapPath(obj)

    end
    %% protected methods
    methods (Access = protected)
        % callback methods
        function obj = goCb(obj, src, ~)
            obj.setFooterStr('running...');
            opt = obj.getParameters();
            opt.oversampleFactor = 5;
            % run simulation
            obj.phtGentor = obj.phtGentor.runSimulation(opt);
            obj = obj.dispResults();
            obj.setFooterStr('operation terminated succesfully');
        end%goCb
        
        function obj = saveCb(obj, ~, ~)
        savePath = obj.getSavePath();
        if ~isdir(savePath)
            mkdir(savePath);
        end
        % delete old files
        delete([savePath '\*.mat']); delete([savePath '\*.xml']);
        % save options 
        options = obj.getParameters();
        savemat([savePath '\generationOptions'],  options);
        struct2xml(struct('root', options), [savePath '\generationOptions.xml']);
        switch  obj.getModelChoice()
            case 'Fermi'
                savemat([savePath '\mbfMap'],  obj.phtGentor.getMbfMap());
                savemat([savePath '\mbvMap'],  obj.phtGentor.getMbvMap());
                savemat([savePath '\mttMap'],  obj.phtGentor.getMttMap());
                savemat([savePath '\residue'],  obj.phtGentor.getResidueSet());
            case 'FtKpsVpVe'
                savemat([savePath '\mbfMap'],  obj.phtGentor.getFtMap());
                savemat([savePath '\mbvMap'],  obj.phtGentor.getVpMap());
                savemat([savePath '\residue'],  obj.phtGentor.getResidueSet());
           	case 'Comp2Exchange'
                savemat([savePath '\mbfMap'],  obj.phtGentor.getFtMap());
                savemat([savePath '\FpMap'],  obj.phtGentor.getFtMap());
                savemat([savePath '\mbvMap'],  obj.phtGentor.getVpMap());
                savemat([savePath '\residue'],  obj.phtGentor.getResidueSet());
            case 'Comp2Exchange_Fp_PS'
                savemat([savePath '\mbfMap'],  obj.phtGentor.getFtMap()./ 60);
                savemat([savePath '\FpMap'],  obj.phtGentor.getFtMap());
                savemat([savePath '\PSMap'],  obj.phtGentor.getPsMap());
                savemat([savePath '\mbvMap'],  ones(size(obj.phtGentor.getFtMap())));
                savemat([savePath '\residue'],  obj.phtGentor.getResidueSet());
        end
        savemat([savePath '\normAifCtc'],  obj.phtGentor.getNormAifCtc());
        savemat([savePath '\tAcq'],  obj.phtGentor.getTAcq());
        savemat([savePath '\ctc'],     obj.phtGentor.getCtcSet());
        savemat([savePath '\noisedCtc'],  obj.phtGentor.getnCtcSet());
        
        obj.setFooterStr('save completed');
        end%saveCb
        
        function obj = dispResults(obj)
            %figure(obj.rPanel);
%             uipanel(obj.rPanel);
            %get(obj.rPanel,'type')
            %set(obj.rPanel, 'Visible', 'yes');
            %             axis(obj.rPanel);
            delete(get(obj.rPanel,'Children'));
            %axes('parent', obj.rPanel);
            colormap jet;
            ha = tight_subplot(2,1,[.05 .03],[.03 .03],[.03 .03], obj.rPanel);
            switch obj.getModelChoice()
                case 'Fermi'
                    axes(ha(1)); hdle(1) = imagesc(obj.phtGentor.getMbfMap());
                    axis image off; title('mbf map');
                    axes(ha(2)); hdle(2) = imagesc(obj.phtGentor.getMbvMap());
                    axis image off; title('mbv map');
                case 'FtKpsVpVe'
                    axes(ha(1)); hdle(1) = imagesc(obj.phtGentor.getFtMap());
                    axis image off; title('Ft map');
                    axes(ha(2)); hdle(2) = imagesc(obj.phtGentor.getVpMap());
                    axis image off; title('Vp map');
                case 'Comp2Exchange'
                    axes(ha(1)); hdle(1) = imagesc(obj.phtGentor.getFtMap());
                    axis image off; title('Ft map');
                    axes(ha(2)); hdle(2) = imagesc(obj.phtGentor.getVpMap());
                    axis image off; title('Vp map');
                case 'Comp2Exchange_Fp_PS'
                    axes(ha(1)); hdle(1) = imagesc(obj.phtGentor.getFtMap());
                    axis image off; title('Ft map');
                    axes(ha(2)); hdle(2) = imagesc(obj.phtGentor.getPsMap());
                    axis image off; title('Vp map');
            end
            for k = 1 : 2
                set(hdle(k), 'ButtonDownFcn', @obj.onImgClickCb);
            end
        end %dispResults
        
        function fig = onImgClickCb(obj, arg1, ~)
            axesHandle  = get(arg1, 'Parent');
            coordinates = get(axesHandle, 'CurrentPoint');
            coordinates = floor(coordinates(1, 1:2));
            if ~coordinates(1); coordinates(1) = 1; end
            if ~coordinates(2); coordinates(2) = 1; end


                sg = obj.phtGentor.getCtc(coordinates(2), coordinates(1));
                noisedSg = obj.phtGentor.getnCtc(coordinates(2), coordinates(1));
                tAcq = obj.phtGentor.getTAcq();
                switch obj.getModelChoice()
                    case 'Fermi'
                        bf = obj.phtGentor.getMbf(coordinates(2), coordinates(1));
                        bv = obj.phtGentor.getMbv(coordinates(2), coordinates(1));
                        titleStr = sprintf('concentration time curve with bf ; %f, bv: %f', bf * 60, bv);
                    case 'FtKpsVpVe'
                        bf = obj.phtGentor.getFt(coordinates(2), coordinates(1));
                        bv = obj.phtGentor.getVp(coordinates(2), coordinates(1));
                        titleStr = sprintf('concentration time curve with bf ; %f, bv: %f', bf * 60, bv);
                    case 'Comp2Exchange'
                        bf = obj.phtGentor.getFt(coordinates(2), coordinates(1));
                        bv = obj.phtGentor.getVp(coordinates(2), coordinates(1));
                        titleStr = sprintf('concentration time curve with bf ; %f, bv: %f', bf * 60, bv);
                    case 'Comp2Exchange_Fp_PS'
                        fp = obj.phtGentor.getFt(coordinates(2), coordinates(1));
                        ps = obj.phtGentor.getPs(coordinates(2), coordinates(1));
                        titleStr = sprintf('fp ; %f, ps: %f', fp , ps);
                    otherwise 
                        return;
                end
                fig = figureMgr.getInstance.newFig('phantomTic');
                hold all; plot(tAcq, sg); plot(tAcq, noisedSg, '--'); legend('signal', 'fitted signal');
                plot(tAcq, obj.phtGentor.getNormAifCtc());
                title(titleStr);
        end%onImgClickCb
        
    end
    %% private methods
    methods (Access = private)
        function obj = FantomeUI()
            obj.phtGentor = phantomGenerator;
        end
        %model choice
        function obj = setmodelChoiceUI(obj)
            %text box
            uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [0 obj.lin(1) 0.4 obj.HdleHeight],...
                'String', 'model');
            %edit box
            obj.mdlChUI = uicontrol(obj.lPanel, 'Style', 'popup',...
                'Units',  'normalized',...
                'Position', [obj.col(3) obj.lin(1) 0.4 obj.HdleHeight],...
                'String', {'Fermi', 'FtKpsVpVe', 'Comp2Exchange', 'Comp2Exchange_Fp_PS', 'BTEX20'});
            set(obj.mdlChUI, 'Callback', @obj.mdlChoiceCb);
        end%setmodelChoiceUI
        
        function obj = setShapeUI(obj)
            %text box
            uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [0.01 obj.lin(2) 0.4 obj.HdleHeight],...
                'String', 'shape');
            %edit box
            obj.shapeUI = uicontrol(obj.lPanel, 'Style', 'popup',...
                'Units',  'normalized',...
                'Position', [obj.col(3) obj.lin(2) 0.4 obj.HdleHeight],...
                'String', {'square', 'myocardium'});
            set(obj.shapeUI, 'Callback', @obj.shapeChoiceCb);
        end%setShapeUI
        
        %UI control
        
        function obj = setAifPathUI(obj)
            %text box
            uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(1) obj.lin(end) 0.1 obj.HdleHeight],...
                'String', 'aif Path');
            %edit box
            obj.aifPathUI = ...
                uicontrol(obj.lPanel, 'Style', 'edit',...
                'Units',  'normalized',...
                'String', 'D:\02_Matlab\Data\SignalSimulation\aifShaper\aifSimu.mat',...
                'Position', [obj.col(2) obj.lin(end) 0.5 obj.HdleHeight]);
        end%setAifPathUI
        
        function obj = setMbfMapPathUI(obj)
            %text box
            uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(1) obj.lin(end - 1) 0.1 obj.HdleHeight],...
                'String', 'mbfmap Path');
            
            %edit box
            obj.mapPathUI = ...
                uicontrol(obj.lPanel, 'Style', 'edit',...
                'Units',  'normalized',...
                'String', 'D:\02_Matlab\Data\deconvTool\deconvolution\Patients\ARBANE\stress\BayesianParallel\apex',...
                'Position', [obj.col(2) obj.lin(end - 1) 0.5 obj.HdleHeight]);
            %
            set(obj.mapPathUI, 'Enable', 'off') 
        end%setMbfMapPathUI

        function setdefaultImage(obj)
            delete(get(obj.rPanel,'Children'));
            ax = axes('parent', obj.rPanel);
            P = phantom('Modified Shepp-Logan',200);
            subplot(2, 1, 1);
            imshow(P);
            subplot(2, 1, 2);
            imshow(P);
        end%setdefaultImage
        
        % models parameters initilization
        function obj = initParametersMap(obj, model)
            
            switch model
                case  'Fermi'
                    obj.slrData.keySet =     {'mbfMin', 'mbfMax',  'mbvMin', 'mbvMax', 't0', 'td', 'sideLength', 'sigma', 'patchWidth', 'oversampleFactor'}; % append set name here
                    obj.slrData.initValSet = {   8,         65,     10,        25,       0,   0,       30,          278,             1,            1       }; %append new param init value
                    obj.slrData.minValSet =  {   1,         50,      1,         10,      0,   0,        2,           5,             1,             1       }; %append new param min value
                    obj.slrData.maxValSet =  { 100,        150,     20,        40,     100,   5,       50,            500,            20,            10       };%append new param max value
                    obj.slrData.factorSet =  {1e-3,       1e-3,    1e-2,      1e-2,     1,    1,        1,           1e-6,            1,             1       };%append new factor value (1 if no need to factor)
                    obj.slrData.unitSet =    {'cc/s/g', 'cc/s/g', 'cc/g',   'cc/g',    's',   's',    'pixels',    'A.U',       'pixels',        'A.U'      };
                    
                case 'Comp2Exchange'
                    obj.slrData.keySet =     {'FpMin',    'FpMax',     'PS',   'VpMin',   'VpMax',  'Ve',  'sigma', 'delay', 'sideLength', 'patchWidth' }; % append set name here
                    obj.slrData.initValSet = {   8,        65,            1,        10,        25,    40,      278,       0,            30,           1  }; %append new param init value
                    obj.slrData.minValSet =  {   1,        50,            1,         1,        10,     0,       1,        0,             2,           1  }; %append new param min value
                    obj.slrData.maxValSet =  { 100,        150,          20,        20,        40,   100,     500,        5,            50,           2  };%append new param max value
                    obj.slrData.factorSet =  {1e-3,        1e-3,        1e-1,      1e-2,     1e-2,  1e-2,    1e-6,        1,             1,           1  };%append new factor value (1 if no need to factor)
                    obj.slrData.unitSet =    {'cc/s/g',    'cc/s/g', 'cc/s/g',   'cc/g',   'cc/g', 'cc/g',  'A.U',       's',     'pixels',     'pixels' };
                    
                case 'Comp2Exchange_Fp_PS'
                    obj.slrData.keySet =     {'FpMin',      'FpMax',     'PSMin',   'PSMax',       'Vp',    'Ve',  'sigma',  'delay', 'sideLength', 'patchWidth' }; % append set name here
                    obj.slrData.initValSet = {   5,           40,           5,         20,            8,      30,     278,         0,           30,           1  }; %append new param init value
                    obj.slrData.minValSet =  {   1,           30,           0,         10,            4,      20,       1,         0,           2,            1  }; %append new param min value
                    obj.slrData.maxValSet =  {  10,           50,          10,         80,           15,      50,     500,         5,          50,            2  };%append new param max value
                    obj.slrData.factorSet =  { 1e-1,         1e-1,       1e-1,       1e-1,         1e-2,    1e-2,    1e-6,         1,           1,            1  };%append new factor value (1 if no need to factor)
                    obj.slrData.unitSet =    {'cc/min/g',  'cc/min/g', 'cc/min/g',  'cc/min/g',   'cc/g', 'cc/g',   'A.U',       's',    'pixels',      'pixels' };
                    
                    
                case 'FtKpsVpVe'
                    obj.slrData.keySet =     {'FtMin',   'FtMax',   'Kps',    'VpMin',  'VpMax',  'Ve',  'delay', 'sideLength','sigma', 'patchWidth' }; % append set name here
                    obj.slrData.initValSet = {   8,         65,      158,        10,       30,     20,       0,        30,       278,         1      }; %append new param init value
                    obj.slrData.minValSet =  {   1,         50,        0,         1,        2,      0,       0,         2,         1,         1      }; %append new param min value
                    obj.slrData.maxValSet =  { 100,        150,      300,        20,       50,    100,       5,        50,      500,         20      };%append new param max value
                    obj.slrData.factorSet =  {1e-3,       1e-3,      1e-4,     1e-2,     1e-2,    1e-2,      1,         1,      1e-6,         1      };%append new factor value (1 if no need to factor)
                    obj.slrData.unitSet =    {'cc/s/g',  'cc/s/g', 'cc/s/g',   'cc/g',    'cc/g', 'cc/g',    's',    'pixels',   'A.U',    'pixels'   };
            end%switch
            
            
            obj.slrData.valMap = containers.Map(obj.slrData.keySet, obj.slrData.initValSet);
            obj.slrData.minValMap = containers.Map(obj.slrData.keySet, obj.slrData.minValSet);
            obj.slrData.maxValMap = containers.Map(obj.slrData.keySet, obj.slrData.maxValSet);
            obj.slrData.paramTextMap = containers.Map(obj.slrData.keySet, obj.slrData.initValSet);
            obj.slrData.editBoxMap = containers.Map(obj.slrData.keySet, obj.slrData.initValSet);
            obj.slrData.sldrMap = containers.Map(obj.slrData.keySet, obj.slrData.initValSet);
            obj.slrData.unitTextMap = containers.Map(obj.slrData.keySet, obj.slrData.initValSet);
            obj.slrData.factorMap = containers.Map(obj.slrData.keySet, obj.slrData.factorSet);
            
            obj.nbHdles = length(obj.slrData.keySet) + 3;
            obj.HdleHeight =  (0.9 - 0.3) / obj.nbHdles;
            obj.lin = 0.9 : -obj.HdleHeight : 0.2;
            obj.col = [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9];
        end%initParametersMap
        
        % sliders
        function obj = dispSldrSet(obj)
            for i = 1 : size(obj.slrData.keySet, 2)
                %set real value for val map
                obj.slrData.valMap(char(obj.slrData.keySet(i))) = obj.slrData.valMap(char(obj.slrData.keySet(i))) * obj.slrData.factorMap(char(obj.slrData.keySet(i)));
                % text
                hPos = obj.lin(i + 2);
                obj.slrData.paramTextMap(char(obj.slrData.keySet(i))) = ...
                    uicontrol(obj.lPanel, 'Style', 'text',...
                    'Units',  'normalized',...
                    'Position', [obj.col(1) hPos 0.1 0.05],...
                    'String', obj.slrData.keySet(i));
                
                %slider
                obj.slrData.sldrMap(char(obj.slrData.keySet(i))) = ...
                    uicontrol(obj.lPanel, 'Style', 'slider',...
                    'Units',  'normalized',...
                    'Value', obj.slrData.valMap(char(obj.slrData.keySet(i))) / obj.slrData.factorMap(char(obj.slrData.keySet(i))),...
                    'Min',obj.slrData.minValMap(char(obj.slrData.keySet(i))), ...
                    'Max',obj.slrData.maxValMap(char(obj.slrData.keySet(i))), ...
                    'Position', [obj.col(2) hPos 0.35 0.05],...
                    'Callback', {@obj.sldrCb, obj.slrData.keySet(i)});
                
                %edit box
                obj.slrData.editBoxMap(char(obj.slrData.keySet(i))) = ...
                    uicontrol(obj.lPanel, 'Style', 'edit',...
                    'Units',  'normalized',...
                    'String', obj.slrData.valMap(char(obj.slrData.keySet(i))),...
                    'Position', [obj.col(6) hPos 0.1 0.05], ...
                    'Callback', {@obj.eboxCb, obj.slrData.keySet(i)});
                
                % units
               
                obj.slrData.unitTextMap(char(obj.slrData.keySet(i))) = ...
                    uicontrol(obj.lPanel, 'Style', 'text',...
                    'Units',  'normalized',...
                    'Position', [obj.col(8) hPos 0.1 0.05],...
                    'String', obj.slrData.unitSet(i));
            end
        end%dispSldrSet
        
    %% callback methods
    function obj = mdlChoiceCb(obj, ~, ~, ~)
        notify(obj, 'modelChanged')
        modelList = get(obj.mdlChUI, 'String');
        modelVal = get(obj.mdlChUI, 'Value');
        model = char(modelList(modelVal));
        persistent localObj;
        localObj = obj.resetSliderDiplay(model);
    end
    function obj = shapeChoiceCb(obj, ~, ~)
        if ~strcmp('myocardium', obj.getShapeChoice())
            state = 'off';
        else
            state = 'on';
        end
        set(obj.mapPathUI, 'Enable', state) 
    end%shapeChoiceCb
    
    function sldrCb(obj, src, arg1, arg2)
        % arg1??? don't know what is used for...
        val  =  floor(get(obj.slrData.sldrMap(char(arg2)), 'Value')) * obj.slrData.factorMap(char(arg2));
        obj.slrData.valMap(char(arg2)) = val;
        set(obj.slrData.editBoxMap(char(arg2)), 'String', num2str(val));
    end
    function eboxCb(obj, src, arg1, arg2)
         val  =  str2num(get(obj.slrData.editBoxMap(char(arg2)), 'String'));
        %str = char(cell(floor(get(source, 'Value'))));
        %nbPE  = str2num(str);
        obj.slrData.valMap(char(arg2)) = val;
        set(obj.slrData.sldrMap(char(arg2)), 'Value', obj.slrData.valMap(char(arg2)) / obj.slrData.factorMap(char(arg2)));
    end
end
end

