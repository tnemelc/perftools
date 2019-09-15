%> @file baseUI.m
%> @brief user interface base class
% =========================================================================
%> @brief base class of perfusion tool GUI. baseUI manages initialization
%> of common controls and sets the guidelines for plugin developpement.
%> To be integrated, a plugin shall have a class the inherits from baseUI
%> and implement member methods getInstance, goCb, saveCb and dispResults
% =========================================================================
classdef baseUI < handle
    properties (Access = protected)
        %> logger
        lgr;
        %> left panel for controls
        lPanel;
        %> right panel for results display
        rPanel;
        %> lines and column tabs for controls display
        col; lin; 
        %> grid for lateral  panel buttons display
        latteralGrid;
        %> run plugin button
        goBtnUI;
        %> browse button for save path
        browseSavePathBnUI;
        %> browse button for data path
        browsePatientPathBnUI;
        %> save button
        saveBtnUI;
        %> help button
        helpBtnUI;
        %> save path editbox
        savePathUI;
        %> controls height to fit controls panel
        HdleHeight;
        %> software data root path
        basePath;
        %> data path edit box 
        dataPathEditBoxUI;
        %> footer 
        footerUI;
        %> image contrast option
        histOpt; 
        %> handle to result axes
        handleAxesTab;
        %> lateral panel buttons handles table
        buttonsPanelTab;
    end
    
    methods (Access = protected)
        % ======================================================================
        %> @brief update save path. mainly used after that data path is updated
        %>
        %> update save path after data path edition
        %>
        %> @param obj object itself
        %> @param arg2 name of the folder folder
        % ======================================================================
        function updateSavePath(obj, folderName)
            path = obj.getDataPath();
            set(obj.savePathUI, 'String', fullfile(path, folderName));
        end%updateSavePath
        
        % ======================================================================
        %> @brief initilize savepath controls
        %> @param obj object itself
        % ======================================================================
        function obj = initSavePathUI(obj)
            %text box
            uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(1) obj.lin(end - 1) 0.1 obj.HdleHeight],...
                'String', 'save Path');
            %edit box
            obj.savePathUI = ...
                uicontrol(obj.lPanel, 'Style', 'edit',...
                'Units',  'normalized',...
                'String', fullfile(obj.basePath, 'tmp'),...
                'Position', [obj.col(2) obj.lin(end - 1) 0.5 obj.HdleHeight]);
            
            % browse 
            obj.browseSavePathBnUI = uicontrol(obj.lPanel, 'Style', 'pushbutton',...
                'Units',  'normalized',...
                'Position', [obj.col(7) obj.lin(end - 1) 0.1 obj.HdleHeight],...
                'String', '...',...
                'Callback', @obj.browseSavePathCb);
        end%initializeSavePathUI
        
        % ======================================================================
        %> @brief callback to savepath browse button.
        %> @param obj object itself
        % ======================================================================
        function obj = browseSavePathCb(obj, ~, ~)
            if isempty(obj.getPatientPath())
                set(obj.savePathUI, 'String', uigetdir(obj.basePath));
            else
                set(obj.savePathUI, 'String', uigetdir(obj.getPatientPath()));
            end
            
        end%browseSavePathCb
        %%
        % ======================================================================
        %> @brief deprecated function better use initDataPathUI
        %> @param obj object itself
        % ======================================================================
        function obj = initPatientPathUI(obj, path)
            obj.lgr.warn('deprecated function : better use initDataPathUI');
            obj = obj.initDataPathUI(path);
        end%initPatientPathUI
        
        %%
        % ======================================================================
        %> @brief init datapath UI controls 
        %> @param obj object itself
        % ======================================================================
        function obj = initDataPathUI(obj, path)
            %text box
            uicontrol(obj.lPanel, 'Style', 'text',...
                'Units',  'normalized',...
                'Position', [obj.col(1) obj.lin(end - 2) 0.1 obj.HdleHeight],...
                'String', 'data path');
            %edit box
            obj.dataPathEditBoxUI = ...
                uicontrol(obj.lPanel, 'Style', 'edit',...
                'Units',  'normalized',...
                'String', path,...
                'Position', [obj.col(2) obj.lin(end - 2) 0.5 obj.HdleHeight]);
            
            % browse
            obj.browsePatientPathBnUI = uicontrol(obj.lPanel, 'Style', 'pushbutton',...
                'Units',  'normalized',...
                'Position', [obj.col(7) obj.lin(end - 2) 0.1 obj.HdleHeight],...
                'String', '...',...
                'Callback', @obj.browsePatientPathCb);
        end%initDataPathUI
        %%
        % ======================================================================
        %> @brief deprecated function better use browseDataPathCb
        %> @param obj object itself
        % ======================================================================
        function obj = browsePatientPathCb(obj, ~, ~)
            obj.lgr.warn('deprecated function');
            obj = obj.browseDataPathCb([], []);
        end%browsePatientPathCb
        %%
        % ======================================================================
        %> @brief callback to datapath browse button.
        %> @param obj object itself
        % ======================================================================
        function obj = browseDataPathCb(obj, ~, ~)
            set(obj.dataPathEditBoxUI, 'String', uigetdir(obj.basePath));
        end%browseDataPathCb
        %%
        % ======================================================================
        %> @brief creates and initializes Go/Save/help buttons
        %> @param obj object itself
        % ======================================================================
        function obj = setButtons(obj)
            
            % Go/Save
            obj.goBtnUI = uicontrol(obj.lPanel, 'Style', 'pushbutton',...
                'Units',  'normalized',...
                'Position', [obj.col(2) obj.lin(end) 0.2 obj.HdleHeight],...
                'String', 'GO!',...
                'Callback', @obj.goCb);
            obj.saveBtnUI = uicontrol(obj.lPanel, 'Style', 'pushbutton',...
                'Units',  'normalized',...
                'Position', [obj.col(4) obj.lin(end) 0.2 obj.HdleHeight],...
                'String', 'Save',...
                'Callback', @obj.saveCb);
            obj.helpBtnUI = uicontrol(obj.lPanel, 'Style', 'pushbutton',...
                'Units',  'normalized',...
                'Position', [obj.col(6) obj.lin(end) 0.1 obj.HdleHeight],...
                'String', '?',...
                'Callback', @obj.helpCb);
        end%setButtons
        %%
        % ======================================================================
        %> @brief empty-feature buttons latteral panel
        %> @param obj object itself
        % ======================================================================
        function obj = initLateralButtonsPanel(obj)
            obj.latteralGrid.sideLen = 0.03;
            figPos = get( gcf, 'pos');
            figSzRatio =  figPos(4) / figPos(3);
            obj.latteralGrid.lin = 0.91 : -obj.latteralGrid.sideLen  : 0.1;
            obj.latteralGrid.col = 0.935 : obj.latteralGrid.sideLen * figSzRatio : 0.99;
            
            obj.buttonsPanelTab(1) = ...
            uicontrol(gcf, 'Style', 'pushbutton',...
                'Units',  'normalized',...
                'Position', [obj.latteralGrid.col(1) obj.latteralGrid.lin(1) (obj.latteralGrid.sideLen * figSzRatio) obj.latteralGrid.sideLen],...
                'String', '1',...
                'Callback', {@obj.setFooterStr, 'clicked button 1'});
            obj.buttonsPanelTab(2) = ...
            uicontrol(gcf, 'Style', 'pushbutton',...
                'Units',  'normalized',...
                'Position', [obj.latteralGrid.col(2) obj.latteralGrid.lin(1) (obj.latteralGrid.sideLen * figSzRatio) obj.latteralGrid.sideLen],...
                'String', '2',...
                'Callback', {@obj.setFooterStr, 'clicked button 2'});
            obj.buttonsPanelTab(3) = ...
            uicontrol(gcf, 'Style', 'pushbutton',...
                'Units',  'normalized',...
                'Position', [obj.latteralGrid.col(3) obj.latteralGrid.lin(1) (obj.latteralGrid.sideLen * figSzRatio) obj.latteralGrid.sideLen],...
                'String', '3',...
                'Callback', {@obj.setFooterStr, 'clicked button 3'});
            obj.buttonsPanelTab(4) = ...
            uicontrol(gcf, 'Style', 'pushbutton',...
                'Units',  'normalized',...
                'Position', [obj.latteralGrid.col(1) obj.latteralGrid.lin(2) (obj.latteralGrid.sideLen * figSzRatio) obj.latteralGrid.sideLen],...
                'String', '4',...
                'Callback', {@obj.setFooterStr, 'clicked button 4'});
            obj.buttonsPanelTab(5) = ...
            uicontrol(gcf, 'Style', 'pushbutton',...
                'Units',  'normalized',...
                'Position', [obj.latteralGrid.col(2) obj.latteralGrid.lin(2) (obj.latteralGrid.sideLen * figSzRatio) obj.latteralGrid.sideLen],...
                'String', '5',...
                'Callback', {@obj.setFooterStr, 'clicked button 5'});
            obj.buttonsPanelTab(6) = ...
            uicontrol(gcf, 'Style', 'pushbutton',...
                'Units',  'normalized',...
                'Position', [obj.latteralGrid.col(3) obj.latteralGrid.lin(2) (obj.latteralGrid.sideLen * figSzRatio) obj.latteralGrid.sideLen],...
                'String', '6',...
                'Callback', {@obj.setFooterStr, 'clicked button 6'});
            
            obj.buttonsPanelTab(7) = ...
            uicontrol(gcf, 'Style', 'pushbutton',...
                'Units',  'normalized',...
                'Position', [obj.latteralGrid.col(1) obj.latteralGrid.lin(3) (obj.latteralGrid.sideLen * figSzRatio) obj.latteralGrid.sideLen],...
                'String', '7',...
                'Callback', {@obj.setFooterStr, 'clicked button 7'});
        end
        %%
        % ======================================================================
        %> @brief empties results panel before new processing
        %> @param obj object itself
        % ======================================================================
        function wipeResults(obj)
            delete(get(obj.rPanel,'Children'));
            obj.handleAxesTab = [];
        end%wipeResults
        % ======================================================================
        %> @brief create footer bar for user messaging
        %> @param obj object itself
        % ======================================================================
        function obj = initFooter(obj)
            obj.footerUI =  uicontrol( 'Style', 'text',...
                'Units','normalized',...
                'Position', [0.01 0.01 0.92 0.03],...
                'String', 'footer', ...
                'HorizontalAlignment', 'left');
        end%initFooter
        
    end% methods(Access= protected)
    methods (Abstract, Static, Access = public)
        % ======================================================================
        %> @brief abstract method. Create a singleton instance of pluginUI.
        % ======================================================================
        obj = getInstance();
    end%(Abstract, Static, Access = public)
    
    methods (Abstract, Access = protected)
            % ======================================================================
            %> @brief abstract method. Go-button call back to launch plugin
            %> processing
            % ======================================================================
            obj = goCb(obj, src, ~);
            % ======================================================================
            %> @brief abstract method. Go-button call back to save plugin
            %> results (usually in the path specified in savePathUI
            % ======================================================================
            obj = saveCb(obj, ~, ~);
            % ======================================================================
            %> @brief abstract method. display Results at the end of plugin
            %> processing . This method shall be called a the end of goCb
            % ======================================================================
            obj = dispResults(obj)
    end%(Abstract, Access = protected)
    
    methods (Access = public)
        % ======================================================================
        %> @brief initialize common plugin panels attributes and UI controls.
        %> function may be derived by inherited class to add specific
        %> plugin controls. At the end of derived function parent super
        %> function is usually needed.
        %> @param hParent 
        %> @param pluginInfo 
        %> @param opt struct that contain miscellaneous informations
        % ======================================================================
        function obj = initialize(obj, hParent, pluginInfo, opt)
            obj.lgr = logger.getInstance();
            figureMgr.getInstance().closeAllBut('deconvTool');
            obj.lin = 0.8 : - 0.05 : 0.1;
            obj.col = 0.1 : 0.1 : 0.9;
            obj.HdleHeight = 0.05;
            % background color
            set(gcf,'Color',ones(1,3) .* 0.3);
            obj.lPanel = uipanel(hParent, 'Title','Controls', ...
                			'Units','normalized', 'Position', ...
								[0.01 0.05 0.35 0.90]);
            switch pluginInfo.backgroundColor.Text
                case 'black'
                    fgcolor = 'white';
                case 'white'
                    fgcolor = 'black';
                otherwise
                    obj.lgr.err('only white and black baground color authorized');
                    return;
            end
            obj.rPanel = uipanel(hParent, 'Title','Results', 'foregroundcolor', fgcolor,...
             'backgroundColor', pluginInfo.backgroundColor.Text, ...
             'Units','normalized', 'Position',[0.35 0.05 0.58 0.90]);
            obj.handleAxesTab = [];
            obj.basePath = opt.rootDataPath.Text;
            if ~isdir(obj.basePath)
                errordlg('error: data root path environnement variable may not be set correctly or directory not created')
                throw(MException('baseUI:initialize', 'error: data root path environnement variable may not be set correctly or directory not created'));
            end
%             obj.basePath = 'C:\Users\creatis\Documents\MATLAB\Qperf\02_data\deconvtool\patientData\IRMAS';
            obj = obj.initSavePathUI();
            obj = obj.setButtons();
            obj = obj.initLateralButtonsPanel();
            obj = obj.initFooter();
            
            obj.histOpt.contrast = 1;
            obj.histOpt.brightness = 0;
            %key press callback
            set(hParent, 'KeyPressFcn', @obj.onKeyPressCb);
        end%initialize
        
        function retVal = setFooterStr(obj, str)
            set(obj.footerUI, 'string', str);
        end%setFooterStr
        
        % getters
        function savePath = getSavePath(obj)
            savePath = get(obj.savePathUI, 'String');
        end%getSavePath
        
        function patientPath = getPatientPath(obj)
            obj.lgr.warn('deprecated function');
            patientPath = obj.getDataPath();
        end%getPatientPath
        %%
        function dataPath = getDataPath(obj)
            dataPath = get(obj.dataPathEditBoxUI, 'String');
        end%getDataPath
    end%(Access = public)
    
    methods (Access = protected)
        function helpCb(obj, ~, ~)
            system('C:\Program Files (x86)\Mozilla Firefox\firefox.exe');
        end%helpCb
        
        function corrIm = correctImage(obj, image)
            maxValue = max(image(:));
            lut(1, :) = (0 : maxValue);
            tmp = obj.histOpt.contrast .*  lut(1, :) + obj.histOpt.brightness;
            tmp(tmp < 0) = 0; tmp(tmp > maxValue) = maxValue;
            lut(2, :) = tmp;
            corrIm = zeros(size(image));
            for k = 1 : numel(image)
                corrIm(k) = lut(2, lut(1,:) == image(k));
            end
        end%correctImage
        
        function validKey = onKeyPressCb(obj, ~, arg)
            validKey = true;
            switch arg.Key
                case 'uparrow'
                    obj.histOpt.brightness = obj.histOpt.brightness + 1;
                case 'downarrow'
                    obj.histOpt.brightness = obj.histOpt.brightness - 1;
                case 'leftarrow'
                    obj.histOpt.contrast = obj.histOpt.contrast - 0.2;
                case 'rightarrow'
                    obj.histOpt.contrast = obj.histOpt.contrast + 0.2;
                case 'h'
                    cprintf('Dgreen', 'help:\nbaseUI\n\th: this help\n\tup arrow increase brightness\n\tdown arrow decrease brightness\n\tleft arrow deacrease contrast\n\tright arrow increase contrast\n');
                    validKey = false;% set validkey false to run inherited functions
                    return;
                otherwise
                    validKey = false;
                    return;
            end%switch
            obj.setFooterStr(sprintf('contrast: %0.1f, brightness: %d', obj.histOpt.contrast, obj.histOpt.brightness));
        end%onKeyPressCb
     
        function savePathOK = checkSavePath(obj)
            % The rule is : you shall save data in patient's subfolder.
            % hence:
            % 1. the savepath root is the same as the patientPath
            % 2. there is at least 1 '\' more
            patientPath = obj.getPatientPath();
            savePath = obj.getSavePath();
            if strncmp(patientPath, savePath, length(patientPath)) || ...
                savePath(length(patientPath) + 1) ~= '\'
                savePathOK = true;
                return;
            end
            
            savePathOK = false;
        end%checkSavePath
        
    end%(Access = protected)
    
    
    methods (Access = private)
        
        
        
    end%methods (Access = private)
end

