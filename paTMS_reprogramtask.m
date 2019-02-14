  function paTMS_reprogramtask
%--------------- -----------------------------------------------------------
% paTMS_reprogamtask: the main function running the "paired-associative TMS
% action reprogramming task" using Matlab and PsychoToolbox

% This file is part of the paTMS experiment 
% Copyright (C) 2016-2017
%               Alberto Lazari      alberto.lazari@univ.ox.ac.uk
%               Olof van der Werf   olof.vanderwerf@ndcn.ox.ac.uk
%               Lennart Verhagen    lennart.verhagen@psy.ox.ac.uk
% version 2017-09-11
%--------------------------------------------------------------------------


%====================
%% INITIALIZE
%====================

% definitions and settings (boolean flags)
cfg = [];
cfg.flg.debug = 0;          % run in debug mode (1) or not (0)
cfg.flg.tms = 1;            % deliver tms pulses (1) or not (0)
cfg.flg.testcond = 0;       % test the condition randomization (1) or not (0)
if ~cfg.flg.debug && ~cfg.flg.tms, warning('Are you sure you don''t want TMS pulses? You are not in debug-mode...'); end
if ~cfg.flg.debug && cfg.flg.testcond, error('The condition randomization can only be tested in debug mode...'); end
cfg.flg.suppresschecks = 2; % supress all PsychToolbox quality checks (2), just the sync testing (1), or none (0)
cfg.flg.dontclear = 1;      % keep stimuli in bugger after `flip` until instructed otherwise
cfg.flg.setpath = 1;        % (re)set the matlab path for PsychToolbox: don't reset (0), reset Psychtoolbox path only when found (1), reset whole matlab path (2)
cfg.flg.primaryscreen = 0;  % use the primary screen to present the stimuli (1) or not (0)

% initialize settings, input/output, display, conditions, logfile
[cfg, pref, log] = Initialize(cfg);

% return quickly if only the condition randomization is tested
if cfg.flg.testcond, return; end

% always perform CleanUp function, even after an error
obj_cleanup = onCleanup(@() CleanUp(cfg.h,pref));

% give instructions, wait for start of session
[tim, log] = StartExp(cfg, log);


%====================
%% MAIN TRIAL LOOP
%====================

% loop over trials
t = 1;
while t <= cfg.n.trial + cfg.n.instr.trial

    
    
  % give a rest before a new block
  if LogGet(log, t, 'break')
    
    % present practice instructions
    if strcmpi(cfg.sessionName,'baseline') && t <= (cfg.n.instr.trial + 1)
      [cfg, log] = PresentPractice(t, cfg, log);
      % write last trial to logfile and start new instruction stage
      if cfg.instr.restart
        LogWrite(log, t);
        t = 1;
        continue;
      end
    end
    
    % present a break
    if t > cfg.n.instr.trial
      cfg = PresentBreak(cfg);
    end
    
  end
  
  % inter-trial interval
  [tim, log] = PresentInterval(t, cfg, tim, log);
  
  % present flankers and cue
  [tim, log] = PresentStimuli(t, cfg, tim, log);
  
  % monitor response and give TMS pulse(s)
  [tim, log] = ResponseAndPulse(t, cfg, tim, log);
 
 % update trial counter
  t = t + 1;
    
 % abort if the ESCAPE key is pressed after cue
  if LogGet(log, t-1, 'respSide') == -1
    break
  end
  
end

%====================
%% WRAP UP
%====================

% write last trial to the logfile on the hard-disk
LogWrite(log, t-1);
% TODO: this will crash if you stop before the first trial...

% wait for some extra time

% log the end

% blank the screen?

% end of experiment screen. We clear the screen once they have made their response
DrawFormattedText(cfg.h.window, 'Thank you!\nThe task is finished.\n\nPress Esc Key To Exit.', 'center', 'center', cfg.colour.white);
Screen('Flip', cfg.h.window);
KbQueueWait;

% please note CleanUp is run automatically at the end, executing `sca`

%====================
%% END OF THE EXPERIMENT
%====================




%====================
%% TRIAL FUNCTIONS
%====================

function Instruction(cfg)
%% Instruction
%--------------------

% welcome to the task
messageStr = ' During the experiment, we are asking you to do a task. \n\n\n Press any key to see what the task will look like... ';
DrawFormattedText(cfg.h.window, messageStr, 'center', 'center', cfg.colour.white);
Screen('Flip', cfg.h.window);
KbStrokeWait;

% explaining the white cue and coloured flankers
Screen('FillRect', cfg.h.window, cfg.colour.white, cfg.rect.cue);
Screen('FillRect', cfg.h.window, cfg.colour.red, cfg.rect.flankerLeft);
Screen('FillRect', cfg.h.window, cfg.colour.green, cfg.rect.flankerRight);
messageStr = ' There will be a white square in the middle, \n\n and two "flankers" on the sides. \n\n\n\n\n\n\n\n\n\n\n\n\n Press any key to continue... ';
DrawFormattedText(cfg.h.window, messageStr, 'center', 'center', cfg.colour.white);
Screen('Flip', cfg.h.window);
KbStrokeWait;

% explain the that the cue will be coloured after a short delay
Screen('FillRect', cfg.h.window, cfg.colour.green, cfg.rect.cue);
Screen('FillRect', cfg.h.window, cfg.colour.red, cfg.rect.flankerLeft);
Screen('FillRect', cfg.h.window, cfg.colour.green, cfg.rect.flankerRight);
messageStr = ' After a short delay, \n\n the cue will become either red or green. \n\n\n\n\n\n\n\n\n\n\n\n\n Press any key to continue... ';
DrawFormattedText(cfg.h.window, messageStr, 'center', 'center', cfg.colour.white);
Screen('Flip', cfg.h.window);
KbStrokeWait;

% instruct which button should be pressed
Screen('FillRect', cfg.h.window, cfg.colour.green, cfg.rect.cue);
Screen('FillRect', cfg.h.window, cfg.colour.red, cfg.rect.flankerLeft);
Screen('FillRect', cfg.h.window, cfg.colour.green, cfg.rect.flankerRight);
messageStr = ' Then, press the key that corresponds with the side of the flanker, \n\n using your index fingers: \n\n left flanker: left key (left index finger) \n\n right flanker: right key (right index finger) \n\n\n\n\n\n\n\n\n\n\n\n\n\n Press any key to continue... \n\n\n\n\n';
DrawFormattedText(cfg.h.window, messageStr, 'center', 'center', cfg.colour.white);
Screen('Flip', cfg.h.window);
KbStrokeWait;

% TODO: give user a chance to abort the test by pressing the ESCAPE key


function TestPulses(cfg)
%% TestPulses
%--------------------
tim = [];

% welcome to the task
messageStr = ' Before we start, we will first deliver three pulses. \n\n\n Press any key to continue... ';
DrawFormattedText(cfg.h.window, messageStr, 'center', 'center', cfg.colour.white);
Screen('Flip', cfg.h.window);
KbStrokeWait;

% prepare black screen for baseline
Screen('FillRect', cfg.h.window, cfg.colour.black);
% add white (fixation) cue
Screen('FillRect', cfg.h.window, cfg.colour.white, cfg.rect.cue);
% present fixation cue on display as soon as possible
Screen('Flip', cfg.h.window);

% give three paired-pulses to help burn in the io64 mex file. This helps
% with the precision of the TMS pulse timing
for c = 1:3
  
  % wait until the TMS stimulators are charged
  if c == 1
    WaitSecs(1);
  else
    WaitSecs(4);
  end
  
  % conditioning pulse
  io64(cfg.h.port, cfg.port.address, cfg.port.condPulse);
  tim.tmsCond = GetSecs;
  WaitSecs('UntilTime',tim.tmsCond + cfg.dur.pulseWidth);
  io64(cfg.h.port, cfg.port.address, cfg.port.zeroLines);
  WaitSecs('UntilTime',tim.tmsCond + cfg.dur.IPI);

  % test pulse
  io64(cfg.h.port, cfg.port.address, cfg.port.testPulse);
  tim.tmsPulse = GetSecs;
  WaitSecs('UntilTime',tim.tmsPulse + cfg.dur.pulseWidth);
  io64(cfg.h.port, cfg.port.address, cfg.port.zeroLines);
  
end

% TODO: give user a chance to abort the test by pressing the ESCAPE key


function [cfg, log] = PresentPractice(t, cfg, log)
%% PresentPractice
%--------------------

% some messages are instructions, others feedback
messageStr = '';
cfg.instr.restart = false;
switch t
  
  % instructions for the start of the practice block
  case 1
  
    % instructions depend on the practice stage
    switch cfg.instr.stage
      case 1
        % do not give TMS pulses
        cfg.instr.tmsOrig = cfg.flg.tms;
        cfg.flg.tms = 0;
        % prepare for practise trials
        messageStr = ' Now, there will be a few introductory trials for you to practice. \n\n\n Press any key to start... ';
      case 2
        % the very first practice block failed, re-doing
      case 3
        % the very first practice block were a success, doing one more time
        messageStr = ' Please try to respond as fast as you can. \n\n Fixate on the middle cue \n\n and use the colour of the cue to speed up your response. \n\n\n\n Press any key to start... ';
      case 4
        % do not give TMS pulses
        cfg.flg.tms = cfg.instr.tmsOrig;
        % ready for the longer practice block
        messageStr = ' Now, there are some more trials with pulses. \n\n\n\n Press any key to start... ';
    end
  
  case cfg.n.instr.trialdummy + 1
    
    % give feedback at the end of the practice block
    if cfg.instr.stage < 4
      
      if cfg.instr.stage < 3
        % feedback stage
        if all(LogGet(log,1:5,'respCorrect')==1)
          messageStr = ' Well done! This is the end of the trial session. \n\n Press any key to continue... ';
          cfg.instr.stage = 3;
        else
          messageStr = ' Unfortunately, not all trials were correct. \n\n Please try again. \n\n Press any key to start... ';
          cfg.instr.stage = 2;
        end
        
      else
        % automatically move to the next (last) stage
        cfg.instr.stage = 4;
        
      end
      
      % repeat or move to a new stage, restart the trial counter
      cfg.instr.restart = true;
      % with the inverted cue colour and instructed side
      cueColour = 3 - LogGet(log,1:cfg.n.instr.trial,'cueColour');
      log = LogSet(log,1:cfg.n.instr.trial,'cueColour',cueColour);
      cueSide = 3 - LogGet(log,1:cfg.n.instr.trial,'cueSide');
      log = LogSet(log,1:cfg.n.instr.trial,'cueSide',cueSide);
      
    end
    
  case cfg.n.instr.trial + 1
  
    % present a white cue for a little bit
    Screen('FillRect', cfg.h.window, cfg.colour.white, cfg.rect.cue);
    Screen('Flip', cfg.h.window);
    WaitSecs(1);
    
    % prepare a message for the end of the practice block
    messageStr = ' During the experiment, we ask you to \n\n keep your hands as relaxed as possible \n\n as well as keeping your head on the chinrest. \n\n Please only move your index fingers when the cue appears. \n\n Press any key to continue to the real experiment... ';
    
end

% present on the screen and wait for key stroke
if ~isempty(messageStr)
  DrawFormattedText(cfg.h.window, messageStr, 'center', 'center', cfg.colour.white);
  Screen('Flip', cfg.h.window);
  KbStrokeWait;
end


function [cfg] = PresentBreak(cfg)
%% PresentBreak
%--------------------
% TODO: give feedback about reaction time?

% give a break
if cfg.n.blockCurr > 0
    
    % present a white cue for a little bit
    Screen('FillRect', cfg.h.window, cfg.colour.white, cfg.rect.cue);
    Screen('Flip', cfg.h.window);
    WaitSecs(1);
    
    % End of the current block
    messageStr = sprintf('End of block %d out of %d. \n\n Please take a rest. \n\n Press any key to continue...', cfg.n.blockCurr, cfg.n.block);
    DrawFormattedText(cfg.h.window, messageStr, 'center', 'center', cfg.colour.white);
    Screen('Flip', cfg.h.window);
    KbStrokeWait;
    
end

% Ready for the new block
cfg.n.blockCurr = cfg.n.blockCurr + 1;
messageStr = sprintf('Starting block %d out of %d. \n\n Press any key to start...', cfg.n.blockCurr, cfg.n.block);
DrawFormattedText(cfg.h.window, messageStr, 'center', 'center', cfg.colour.white);
Screen('Flip', cfg.h.window);
KbStrokeWait;
    
% TODO: give user a chance to abort the test by pressing the ESCAPE key


function [tim, log] = PresentInterval(t, cfg, tim, log)
%% PresentInterval
%--------------------
% prepare black screen for baseline
Screen('FillRect', cfg.h.window, cfg.colour.black);
% add white (fixation) cue
Screen('FillRect', cfg.h.window, cfg.colour.white, cfg.rect.cue);

% present interval cue on display as soon as possible
tim.flip = Screen('Flip', cfg.h.window, 0, 1);
tim.interval = tim.flip;

% store the time of the interval in the log
log = LogSet(log, t, 'timeInterval', tim.interval);

% write previous trial to the logfile on the hard-disk
if t > 1
  LogWrite(log, t-1);
end

% TODO: give user a chance to abort the test by pressing the ESCAPE key


function [tim, log] = PresentStimuli(t, cfg, tim, log)
%% PresentStimuli
%--------------------
% retrieve the cue colours
if LogGet(log, t, 'cueColour') == 1
  cueColour = cfg.colour.red;
else
  cueColour = cfg.colour.green;
end
% retrieve the flanker colours
if LogGet(log, t, 'flankerLeft') == 1
  flankerLeftColour = cfg.colour.red;
  flankerRightColour = cfg.colour.green;
else
  flankerLeftColour = cfg.colour.green;
  flankerRightColour = cfg.colour.red;
end

% add flankers (white cue is still present from the interval)
Screen('FillRect', cfg.h.window, flankerLeftColour, cfg.rect.flankerLeft);
Screen('FillRect', cfg.h.window, flankerRightColour, cfg.rect.flankerRight);

% calculate intended time of the next flip (after interval minus a buffer)
tim.flanker = tim.flip + cfg.dur.interval - cfg.dur.buffer;

% present flankers on display
tim.flip = Screen('Flip', cfg.h.window, tim.flanker, 1);
tim.flanker = tim.flip;

% calculate intended time of the next flip (450-600 ms after flankers minus a buffer)
tim.cue = tim.flip + cfg.dur.flanker(t) - cfg.dur.buffer;

% add the coloured cue
Screen('FillRect', cfg.h.window, cueColour, cfg.rect.cue);

% present coloured cue on display
tim.flip = Screen('Flip', cfg.h.window, tim.cue, 0);
tim.cue = tim.flip;

% store the time of the flankers and cue in the log
log = LogSet(log, t, 'timeFlanker', tim.flanker);
log = LogSet(log, t, 'timeCue', tim.cue);


function [tim, log] = ResponseAndPulse(t, cfg, tim, log)
%% GivePulse
%--------------------
% TODO: check if button was prematurely pressed

% initialize TMS pulse with zeros
tim.tmsCond = 0;
tim.tmsPulse = 0;

% give a pulse on this trial or not?
if LogGet(log, t, 'tmsPulse') == 0 || ~cfg.flg.tms
  % just wait for the response, no TMS pulse
  [tim.response, key] = WaitResponse(cfg.h.keyboard, [cfg.key.left cfg.key.right], 1, tim.flip+cfg.dur.maxRT, cfg.key.escape, 1);

else
  
  % calculated intended time of the TMS pulse (single or paired pulse)
  if LogGet(log, t, 'tmsPulse') == 2
    % paired pulse
    tim.tmsPulse = tim.flip + cfg.dur.tmsPulse - cfg.dur.IPI;
  else
    % single pulse
    tim.tmsPulse = tim.flip + cfg.dur.tmsPulse;
  end
  % buffer = 0.001; % a minimal buffer to account for computing delays
  buffer = 0; % WaitResponse is fast, no need for a buffer
  
  % wait for response
  [tim.response, key] = WaitResponse(cfg.h.keyboard, [cfg.key.left cfg.key.right], 1, tim.tmsPulse-buffer, cfg.key.escape, 1);
    
    % paired pulse or not?
    if LogGet(log, t, 'tmsPulse') == 2
      % conditioning pulse
      io64(cfg.h.port, cfg.port.address, cfg.port.condPulse);
      tim.tmsCond = GetSecs;
      WaitSecs('UntilTime',tim.tmsCond + cfg.dur.pulseWidth);
      io64(cfg.h.port, cfg.port.address, cfg.port.zeroLines);
      WaitSecs('UntilTime',tim.tmsCond + cfg.dur.IPI);
    end
    
    % test pulse
    io64(cfg.h.port, cfg.port.address, cfg.port.testPulse);
    tim.tmsPulse = GetSecs;
    WaitSecs('UntilTime',tim.tmsPulse + cfg.dur.pulseWidth);
    io64(cfg.h.port, cfg.port.address, cfg.port.zeroLines); 

    if key == 0
    
    % continue to wait for response
    [tim.response, key] = WaitResponse(cfg.h.keyboard, [cfg.key.left cfg.key.right], 1, tim.flip+cfg.dur.maxRT, cfg.key.escape, 0);

  else
    
    % response key is already pressed, skip TMS pulse but log with negative value
    %tim.tmsPulse = 0;
    
    log = LogSet(log, t, 'tmsPulse', -LogGet(log, t, 'tmsPulse'));
    
  end
  
end

% TODO: wakey wakey if dur.maxRT?
%if key == 0
  % wakey wakey
%end

% process the response
switch key
  case 0
    respSide = 0;
    respCorrect = 0;
    respRT = -1;
  case {cfg.key.left, cfg.key.right}
    if key == cfg.key.left
      respSide = 1;
    elseif key == cfg.key.right
      respSide = 2;
    end
    if respSide == LogGet(log, t, 'cueSide')
      respCorrect = 1;
    else
      respCorrect = -1;
    end
    respRT = tim.response - tim.cue;
  otherwise
    respSide = -abs(key);
    respCorrect = 0;
    respRT = -1;
end

% compare response to previous trial
respStaySwitch = 0;
if respSide > 0 && ~LogGet(log, t, 'break')
  respStaySwitch = 1 + (respSide ~= LogGet(log, t-1, 'respSide'));
end

% store the response in the log
log = LogSet(log, t, 'respSide', respSide);
log = LogSet(log, t, 'respStaySwitch', respStaySwitch);
log = LogSet(log, t, 'respCorrect', respCorrect);
log = LogSet(log, t, 'respRT', respRT);

% store the TMS pulse and response times in the log
log = LogSet(log, t, 'timeTmsCond', tim.tmsCond);
log = LogSet(log, t, 'timeTmsPulse', tim.tmsPulse);
log = LogSet(log, t, 'timeResponse', tim.response);




%====================
%% OVERHEAD FUNCTIONS
%====================

function [cfg, pref, log] = Initialize(cfg)
%% Initialize
%--------------------
cfg.h = [];

% query for parameters and names
sessionList = {'baseline','expression','post'};
if cfg.flg.debug
  % hard code the subject and session name
  cfg.subjectName = 'debug';
  sessionIdx = 1; % don't pick the 'baseline' session, it has instructions
else
  cfg.subjectName = strjoin(inputdlg('Subject ID'));
  sessionIdx = listdlg(...
    'PromptString','What session?',...
    'ListSize',[160 120],...
    'SelectionMode','single',...
    'ListString',sessionList);
end
cfg.sessionName = sessionList{sessionIdx};

% set the random number generator
if cfg.flg.debug
  rng('default'); % use a reproducable order when in debug mode
else
  rng('shuffle');
end

% do not start initialize the experiment if only a test of the condition
% randomization is requested
if cfg.flg.testcond
  % initialize conditions
  pref = [];
  [cfg, log] = InitLog(cfg);
  [cfg, log] = InitCond(cfg, log);
  return
end

% (re)set Psychtoolbox path
SetPathPsychToolbox(cfg);

% set up PsychToolbox
PsychDefaultSetup(2); % should be at least 1 to ensure that keynaming is similar across all operating systems

% initialize the input and output devices
cfg = InitInputOutput(cfg);

% initialize the display
[cfg, pref] = InitDisplay(cfg);

%% initialize stimuli, conditions, durations, and logfile
%------------------------
% initialize stimuli
cfg = InitStim(cfg);

% initialize the logfile
[cfg, log] = InitLog(cfg);

% initialize conditions
[cfg, log] = InitCond(cfg, log);

% prepare instruction trials
[cfg, log] = PrepareInstruction(cfg, log);

% initialize durations
cfg = InitDur(cfg);


function SetPathPsychToolbox(cfg)
%% SetPathPsychToolbox
%--------------------

% test whether PsychToolbox is on the path
if ~isempty(regexpi(path,'psychtoolbox','once'))
  % PsychToolbox is found on the path
  
  % switch depending on flag
  if cfg.flg.setpath == 1
    % remove the PsychToolbox folders from the path
    fprintf('\nRemoving existing PsychToolbox folders from path.\n');
    pathSplit = regexp(path,pathsep,'split');
    idx = ~cellfun(@isempty,regexpi(pathSplit,'psychtoolbox','once'));
    pathRemove = strcat(pathSplit(idx),pathsep);
    pathRemove = strcat(pathRemove{:});
    rmpath(pathRemove);
    
  elseif cfg.flg.setpath == 2
    % reset the whole matlab path before continuing
    restoredefaultpath;
    
  else % cfg.flg.setpath == 0
    % Nothing has to be done, return to caller
    return
    
  end % cfg.flg.setpath
  
end

% add Psychtoolbox to the path
disp('Setting up path for PsychToolbox.');

% define location of PsychToolbox (usually in the matlabroot/toolbox)
if ispc, userName=getenv('USERNAME'); else, userName=getenv('USER'); end
switch lower(userName)
  case 'lab' % in the lab
    dirPT = fullfile('C:','Program Files','Psychtoolbox');
  case 'lennart' % on my laptop
    dirPT = fullfile(userpath,'toolbox','PsychToolbox');
  otherwise
    error('User not recognized: location of Psychtoolbox not known');
end

% check if multiple PsychToolbox versions are found
versionListPT = dir([dirPT '*']);
if isempty(versionListPT)
  error('No PsychToolbox found in specified location: %s',dirPT);
elseif length(versionListPT) == 1
  versionPT = versionListPT(1).name;
  % fprintf('\nOne PsychToolbox version found: %s\n',versionPT);
else
  str = sprintf('\nPsychToolbox versions found:\n');
  kk = 1:length(versionListPT);
  for k = kk
    str = sprintf('%s\t[%d]\t%s\n',str,k,versionListPT(k).name);
  end
  str = sprintf('%sPlease select a version: ',str);
  sel = str2num(input(str,'s'));
  while ~ismember(sel,kk)
    str = sprintf('Please select one of the following numbers [%s]: ',num2str(kk));
    sel = str2num(input(str,'s'));
  end
  versionPT = versionListPT(sel).name;
  fprintf('Selected version: %s\n',versionPT);
end

% update PsychToolbox location to chosen version
dirPT = fileparts(dirPT);
dirPT = fullfile(dirPT,versionPT);

% generate path to be included
pathPT = genpath(dirPT);
% do not inlcude the svn folder
pathPTRemove = genpath(fullfile(dirPT,'.svn'));
pathPT = strrep(pathPT,pathPTRemove,'');
% for Windows: place the operating system specific basics folder above the general basics
if ispc
  pathPTBasic1 = genpath(fullfile(dirPT,'PsychBasic'));
  pathPTBasic2 = [fullfile(dirPT,'PsychBasic','MatlabWindowsFilesR2007a') ';'];
  pathPTBasic2 = [pathPTBasic2 strrep(pathPTBasic1,pathPTBasic2,'')];
  pathPT = strrep(pathPT,pathPTBasic1,pathPTBasic2);
else
  %error('linux and OSX not supported yet');
end

% add psychtoolbox to path
addpath(pathPT)

% run startup from PsychToolbox
if (exist('PsychStartup','file') == 2)
  PsychStartup;
elseif (exist('SetupPsychtoolbox','file') == 2)
  SetupPsychtoolbox;
else
  %warning('SetupTest:SetPath:Psychtoolbox','PsychToolbox startup script could not be located.');
  disp('An older version of PsychToolbox is selected. The PsychStartup script cannot be run.');
end


function cfg = InitInputOutput(cfg)
%% InitInputOutput
%------------------------

%% set up keyboard and mouse
%--------------------
% start a keyboard queue to record the key presses and releases
cfg.h = StartKeyBoardQueue(cfg.h);

% set target keys
cfg.key.escape = KbName('ESCAPE'); % 41 on macOS
if ispc
  cfg.key.left = KbName('LeftControl');
  %cfg.key.right = KbName('RightControl');
  %cfg.key.right = KbName('RightArrow');
  cfg.key.right = KbName('Return');
else
  cfg.key.left = KbName('LeftGUI'); % 227 on macOS
  cfg.key.right = KbName('RightGUI'); % 231 on macOS
end

% move the cursor to the centre of the screen
%SetMouse(cfg.pos.xCentre, cfg.pos.yCentre);
if cfg.flg.debug
  % show cursor as an arrow
  ShowCursor('Arrow');
else
  % hide the mouse cursor
  HideCursor;
end

%% set up parallel port interface
%--------------------
if cfg.flg.tms
  try
    % initialize an input/output port
    cfg.h.port = io64;

    % query the status
    cfg.port.status = io64(cfg.h.port);
    if cfg.port.status ~= 0
      error('input/output port setup failed');
    end

    % hardware address of the parallel port
    cfg.port.address = hex2dec('D020');
  catch ME
    if cfg.flg.debug && ~ispc
      warning('input/output port only supported on Windows, simply skipping now');
    else
      rethrow(ME);
    end
  end

  % parallel port code values for TTL pulses (and zero on all lines)
  cfg.port.testPulse = 32;
  cfg.port.condPulse = 64;
  cfg.port.zeroLines = 0;

else
  % no port initialized
  cfg.port = [];
  
end

function h = StartKeyBoardQueue(h)
%% StartKeyBoardQueue
%------------------------
if nargin < 1, h = []; end

% only listen to the FORP device
% cfg.h.keyboard = -1;
%
% % List of vendor IDs for valid FORP devices:
% vendorIDs = [1240 6171];
%
% Devices = PsychHID('Devices');
% % Loop through all KEYBOARD devices with the vendorID of FORP's vendor:
% for i = 1:size(Devices,2)
%     if (strcmp(Devices(i).usageName,'Keyboard') || strcmp(Devices(i).usageName,'Keypad')) && ismember(Devices(i).vendorID, vendorIDs)
%         cfg.h.keyboard = i;
%         break;
%     end
% end
%
% if cfg.h.keyboard == -1;
%     error('No FORP-Device detected on your system');
% end
h.keyboard = [];

% disable keyboard for Matlab
%ListenChar(2);

% initialize cue
KbQueueCreate(h.keyboard);
% start recording
KbQueueStart(h.keyboard);


function [cfg, pref] = InitDisplay(cfg)
%% InitDisplay
%------------------------

%% setup performance checks and clean-up
%------------------------
% Screen is able to do a lot of configuration and performance checks on
% open, and will print out a fair amount of detailed information when
% it does. This checking behavior can be suppressed if you would like so.
pref = [];
if cfg.flg.suppresschecks > 0
  % change the testing parameters
  %default: Screen('Preference','SyncTestSettings' [, maxStddev=0.001 secs][, minSamples=50][, maxDeviation=0.1][, maxDuration=5 secs]);
  [p1, p2, p3, p4] = Screen('Preference','SyncTestSettings',0.001,50,0.1,5);
  pref.old.SyncTestSettings = num2cell([p1 p2 p3 p4]);
  if cfg.flg.suppresschecks > 1
    % and suppress them completely
    pref.old.SkipSyncTests = Screen('Preference','SkipSyncTests',1);
    pref.old.VisualDebugLevel = Screen('Preference','VisualDebugLevel',3);
    pref.old.SupressAllWarnings = Screen('Preference','SuppressAllWarnings',1);
  end
end
% TODO: on macOS it seems there are still warnings displayed. Why?!?
%Screen('Preference', 'VisualDebuglevel', 3)

%% setup display
%------------------------
% get screen handles
cfg.h.allscreens = Screen('Screens');

% use primary or secondary screen to present stimuli
if cfg.flg.primaryscreen
  % use primary display
  if ispc
    cfg.h.screen = min(max(cfg.h.allscreens),1);
  else
    cfg.h.screen = min(cfg.h.allscreens);
  end
else
  % use secondary display
  cfg.h.screen = max(cfg.h.allscreens);
end

% define colors
cfg.colour.black = BlackIndex(cfg.h.screen);
cfg.colour.white = WhiteIndex(cfg.h.screen);
cfg.colour.gray = (cfg.colour.black+cfg.colour.white)/2;
cfg.colour.red = [1 0 0]';
cfg.colour.green = [0 1 0]';
cfg.colour.blue = [0 0 1]';

% initialize the size of the display window
if cfg.flg.debug
  cfg.pos.win = [0 0 640 480];
else
  cfg.pos.win = [];
end

% open a display window, get the window handle and size
[cfg.h.window, cfg.pos.win] = PsychImaging('OpenWindow', cfg.h.screen, cfg.colour.black, cfg.pos.win, 32, 2);

% retrieve the size of the display window
[cfg.pos.width, cfg.pos.height] = Screen('WindowSize', cfg.h.window);
[cfg.pos.xCentre, cfg.pos.yCentre] = RectCenter(cfg.pos.win);

% switch to realtime-priority to reduce timing jitter and interruptions
% caused by other applications and the operating system itself:
if ispc
  Priority(0);
  %Priority(1); % This is not real-time priority to give the screen-capture program a chance to run smoothly
else
  Priority(MaxPriority(cfg.h.window));
end

% get the flip interval (time between frame refresh)
cfg.dur = [];
cfg.dur.frame = Screen('GetFlipInterval',cfg.h.window);
% calculate a buffer of half a frame rate
cfg.dur.buffer = cfg.dur.frame/2;


function cfg = InitStim(cfg)
%% InitStim
%------------------------

% set cue and flanker dimensions
if cfg.flg.debug
  cfg.rect.cueBase = [0 0 cfg.pos.width/32 cfg.pos.width/32];
  cfg.rect.flankerBase = [0 0 cfg.pos.width/8 cfg.pos.width/8];
else
  cfg.rect.cueBase = [0 0 50 50];
  cfg.rect.flankerBase = [0 0 200 200];
end

% set flanker coordinates
xShiftFlanker = cfg.pos.width/4;
xPosFlankerLeft = cfg.pos.xCentre - xShiftFlanker;
xPosFlankerRight = cfg.pos.xCentre + xShiftFlanker;

% define flanker rectangles
cfg.rect.flankerLeft = CenterRectOnPointd(cfg.rect.flankerBase, xPosFlankerLeft, cfg.pos.yCentre);
cfg.rect.flankerRight = CenterRectOnPointd(cfg.rect.flankerBase, xPosFlankerRight, cfg.pos.yCentre);

% define cue rectangle
cfg.rect.cue = CenterRectOnPointd(cfg.rect.cueBase, cfg.pos.xCentre, cfg.pos.yCentre) ;


function [cfg, log] = InitLog(cfg)
%% InitLog
%----------
% initialize
log = [];

% set a log directory
log.subjectName = cfg.subjectName;
log.sessionName = cfg.sessionName;
log.dir = fullfile(fileparts(mfilename('fullpath')),'log');
if ~exist(log.dir,'dir'), mkdir(log.dir); end

% filename for the header
log.fileName.header = sprintf('logfile_header_%s_%s.txt',log.subjectName,log.sessionName);
log.fileName.header = fullfile(log.dir,log.fileName.header);

% filename for the logfile trial data
log.fileName.data = sprintf('logfile_data_%s_%s.txt',log.subjectName,log.sessionName);
log.fileName.data = fullfile(log.dir,log.fileName.data);

% variables in the logfile
% general
%   1. trialNumber      number of the trial in the session (1:cfg.n.trial)
%   2. sequenceNumber   number of the sequence in the session (1:cfg.n.sequence)
%   3. sequenceTrial    number of the trial within a sequence (1:[4 7])
%   4. break            the trial/sequence is preceded by a break (1) or not (0)
% flanker
%   5. flankerLeft      the colour of the left flanker, red (1) or green (2)
%   6. flankerRight     the colour of the right flanker, red (1) or green (2)
% cue
%   7. cueColour        the colour of the cue, red (1) or green (2)
%   8. cueSide          the side (hand) cued to respond with, left (1) or right (2)
%   9. cueStaySwitch    whether the cue colour stays the same as the previous trial (1) or switches (2)
%  10. sideStaySwitch   whether the cued side/hand stays the same as the previous trial (1) or switches (2)
% TMS pulse
%  11. tmsPulse         the type of TMS pulse on the trial, none (0), single (1), or paired (2)
% response
%  12. respSide         the given response, left (1) or right (2), or absent (0)
%  13. respStaySwitch   whether the given response stayed the same as the previous side (1) or switches (2)
%  14. respCorrect      whether the given response was correct (1), incorrect (-1), or absent (0)
%  15. respRT           the reaction time in ms
% event timing
%  16. timeInterval
%  17. timeFlanker
%  18. timeCue
%  19. timeTmsCond
%  20. timeTmsPulse
%  21. timeResponse

% set the logfile variables
log.varName = {...
  'trialNumber', 'sequenceNumber', 'sequenceTrial', 'break',...
  'flankerLeft', 'flankerRight',...
  'cueColour', 'cueSide', 'cueStaySwitch', 'sideStaySwitch',...
  'tmsPulse',...
  'respSide', 'respStaySwitch', 'respCorrect', 'respRT',...
  'timeInterval', 'timeFlanker', 'timeCue', 'timeTmsCond', 'timeTmsPulse', 'timeResponse'};

% how to identify timing variables in the logfile
log.tim.varIdentifier = '^time';


function [cfg, log] = InitCond(cfg, log)
%% InitCond
%------------------------

% a few settings on how to bias the assignment of pulses to trials
flgBiasSwitchToDesign = true;
flgBiasStayToSeqMiddle = true;
flgBiasStayToNotAssigned = true;
flgBiasStayToNotAssignedMethod = 'absolute';

% do not allow more than 1000 iterations of a nested while loop before breaking
maxWhileLoopIter = 10^3;


%% experimental factorial design
%----------------------------------------

% specify the number of task conditions and pulses
cfg.n.pulseType = 2;      % single and paired pulses
cfg.n.cueStaySwitch = 2;  % cue colour stay and switch
cfg.n.side = 2;           % response side/hand left and right
cfg.n.sideStaySwitch = 2; % response side/hand stay and switch
cfg.n.condCell = cfg.n.cueStaySwitch * cfg.n.side * cfg.n.sideStaySwitch * cfg.n.pulseType;
cfg.n.pulseCondCell = 7;  % 7 pulses for each cell combination
cfg.n.pulse = cfg.n.condCell * cfg.n.pulseCondCell; % total number of pulses

% do not deliver a TMS pulse on the three trials after a break/start
cfg.n.afterBreak = 3;
% do not deliver a TMS pulse on the two trials after a switch trial
cfg.n.afterSwitch = 2;
% do not deliver a TMS pulse three trials before or after another TMS pulse
cfg.n.aroundPulse = 3;

% define the task conditions, create a repeatable condition matrix
condTile = 1 + cellfun(@str2double, num2cell(dec2bin(0:(cfg.n.condCell-1))));

% prepare the pseudo-randomisation for
% cueStaySwitch * side * sideStaySwitch * pulseType
cfg.n.cond = size(condTile,2);

% do not allow more than 3 sequences in a row to repeat the same condition
maxCondRepetition = 3;

% do not allow more than 4 repetitions of responding with the same hand
maxSideRepetition = 4;


%% sequence and block settings
%----------------------------------------

% the set of sequence lengths
sequenceVal = [4 5 6 7 8]; % original
%sequenceVal = [5 6 7 8]; % suggestion

% set number of blocks (separated by breaks) and block counter
cfg.n.block = 4;
cfg.n.blockCurr = 0;


%% iterate and pick the best solution
%----------------------------------------

% iteration settings to find the best randomization of conditions
bestIter = 0;
maxIter = 100;
bestSolution = Inf;
bestLog = [];

% report on iteration
orderOfMagnitude = 1+floor(log10(maxIter));
strSpaces = repmat(' ',1,orderOfMagnitude);
strBackSpaces = repmat('\b',1,orderOfMagnitude);
strIter = sprintf('%%%dd',orderOfMagnitude);
fprintf('randomizing conditions (%d iterations)...\nplease hold on\niteration %s',maxIter,strSpaces)

% iterate full randomization
for iter = 1:maxIter
  fprintf([strBackSpaces strIter],iter);
  
  
  %% pseudo-randomize factorial design
  %----------------------------------------

  % initialize the nPulse * nCond
  pulseCond = nan(cfg.n.pulse,cfg.n.cond);
  % create the pseudo-randization per block so that the conditions are evenly
  % spread over time with all combinations occuring in every block (once).
  for c = 1:cfg.n.pulseCondCell
    % identify which pulses this "block" occupies
    idx = (1+((c-1)*cfg.n.condCell)) : (c*cfg.n.condCell);
    % re-do the randomization until it matches the criteria
    while true
      % randomly permute conditions
      pulseCond(idx,:) = condTile(randperm(cfg.n.condCell),:);
      % initialize a check for repetitions
      countRepetitions = zeros(1,cfg.n.cond);
      pulseCondToInspect = [-inf(1,cfg.n.cond); pulseCond(1:idx(end),:); inf(1,cfg.n.cond)];
      % check for each condition whether there isn't too much repetition
      for d = 1:cfg.n.cond
        % find the longest streak of repetitions per condition
        countRepetitions(d) = max(diff(find(diff(pulseCondToInspect(:,d)))));
      end
      % if all conditions are not repeated too much, then break the while loop
      if all(( countRepetitions - (maxCondRepetition * ones(1,cfg.n.cond)) )<=0), break; end
    end
  end

  % add one more sequence (without a pulse) to the end
  pulseCond = [pulseCond; zeros(1,cfg.n.cond)];

  % define the number of sequences
  cfg.n.sequence = size(pulseCond,1);

  % name the pulse conditions for ease of retrieval
  seqCueStaySwitch = pulseCond(:,1);
  seqCueStay = seqCueStaySwitch == 1;
  seqCueSwitch = seqCueStaySwitch == 2;
  seqCueSide = pulseCond(:,2);
  seqSideStaySwitch = pulseCond(:,3);
  seqPulseType = pulseCond(:,4);

  % randomly assign the cue colour and alternate
  switch randi(2)
    case 1
      seqCueColour = mod(1:cfg.n.sequence, 2) + 1;
    case 2
      seqCueColour = ~mod(1:cfg.n.sequence, 2) + 1;
  end


  %% define desired sequence lengths
  %----------------------------------------

  % distribute them to add up to the number of sequences
  nSequenceVal = numel(sequenceVal);
  sequenceCount = repmat(floor(cfg.n.pulse/nSequenceVal),1,nSequenceVal);
  nAddToComplete = mod(cfg.n.pulse,nSequenceVal);
  addToComplete = [zeros(1,nSequenceVal-nAddToComplete) ones(1,nAddToComplete)];
  sequenceCount = sequenceCount + addToComplete;

  % create a set of sequence lengths to pick from
  sequenceSet = arrayfun(@(a,b) repmat(a,1,b), sequenceVal, sequenceCount,'UniformOutput',false);
  sequenceSet = [sequenceSet{:}]';

  % calculate the number of trials
  cfg.n.trial = sum(sequenceSet);

  % define the trial numbers (within a sequence) of interest
  minNum = max(min(sequenceVal), cfg.n.afterSwitch + 2);
  maxNum = max(sequenceVal);
  numVal = minNum:maxNum;
  nNumVal = numel(numVal);

  % count the occurences of trial numbers (within a sequence)
  numCount = zeros(1,nNumVal);
  for c = 1:nNumVal
    numCount(c) = sum((numVal(c) <= sequenceVal) .* sequenceCount);
  end


  %% define desired trial number distribution
  %----------------------------------------

  % calculate the relative distribution of sequence lengths
  sequenceDist = sequenceCount/cfg.n.pulse;

  % calculate the relative distribution of trial numbers (within sequence)
  numDist = numCount/sum(numCount);

  % match the sequence length count to the trial number count
  if nNumVal > nSequenceVal
    sequenceDistMatch = interp1(sequenceVal,sequenceDist,numVal,'linear','extrap');
  else
    sequenceDistMatch = sequenceDist;
  end

  % define the ideal distribution of the mean of the trial numbers and
  % sequence lengths
  %sequenceDistIdeal = sequenceDistMatch;
  %sequenceDistIdeal = numDist;
  sequenceDistIdeal = mean([sequenceDistMatch; numDist],1);
  
  % retrieve the probability of very short and not-so-short sequences
  probShortSeq = sequenceDistIdeal(sequenceVal < 5);
  probLongSeq = sequenceDistIdeal(find(sequenceVal >= 5,1,'first'));
  % set the probability of the short to the average of short and longish
  probShortSeq = (probShortSeq+probLongSeq)/2;
  sequenceDistIdeal(sequenceVal < 5) = probShortSeq;
  % re-balance the probabilities
  sequenceDistIdeal = sequenceDistIdeal/sum(sequenceDistIdeal);  

  % use the same distribution to assign the trial numbers of the stay pulses
  %numDistIdeal = numDist;
  numDistIdeal = sequenceDistIdeal;

  
  %% assign sequence lengths to restricted (sets of) conditions
  %----------------------------------------
  % TODO: should the switch sequences have a maximum restriction, to bias in
  % favour of lower sequences before switch trials?
  % restrictions on minimal sequence length
  % 1.  the stay sequence after a switch sequence should be at
  %     cfg.n.aroundPulse (3) + 2 (one switch and one stay trial)

  % initialize indices and counter for pulses that have restrictions on their minimal sequence lengths
  sequenceRestriction = [];
  seqMinLength = zeros(cfg.n.sequence,0);
  c = 1;

  % restriction 1. if the first sequence is stay before switch
  if seqCueStay(1) && seqCueSwitch(2)
    sequenceRestriction(c) = 2 + cfg.n.afterBreak + cfg.n.aroundPulse;
    seqMinLength(:,c) = zeros(cfg.n.sequence,1);
    seqMinLength(1,c) = 1;
    c = c + 1;
  end

  % restriction 2. stay pulse followed by a switch pulse
  sequenceRestriction(c) = 2 + cfg.n.aroundPulse;

  % identify pulses that require a minimum sequence length
  if min(sequenceVal) < sequenceRestriction(c)
    % identify when a stay TMS pulse is preceded by a switch pulse
    seqMinLength(:,c) = seqCueStay & [false; seqCueSwitch(1:end-1)];
    % if the very first pulse is stay, add this to the restricted sequences
    if seqCueStay(1), seqMinLength(1,c) = 1; end
    % update counter (when more restrictions are added)
    %c = c + 1;
  end

  % ensure there is no overlap (and the most strict criterion holds precedence)
  seqMinLength = diff([zeros(cfg.n.sequence,1) cumsum(seqMinLength,2)==1],1,2) == 1;

  % initialize zero sequence length for all pulses
  seqLength = zeros(cfg.n.sequence,1);

  % factorial design
  idxDesign = [seqCueStaySwitch seqPulseType seqCueSide seqSideStaySwitch];

  % loop over restricted sequences (most strict first)
  for c = 1:size(seqMinLength,2)
    % select fitting sequence lengths
    sequenceSubset = sequenceSet(sequenceSet >= sequenceRestriction(c));
    nSequenceSubset = numel(sequenceSubset);
    nSequenceRequired = sum(seqMinLength(:,c));
    % find available sequence lengths
    if nSequenceSubset < nSequenceRequired
      error('not enough sequences available (%d) of sufficient length (%d trials)\n',nSequenceSubset,sequenceRestriction(c))
    end

    % select sequence lengths according to the ideal distribution
    if flgBiasSwitchToDesign

      % take the factorial design into account
      [seqLength, sequenceSubset] = FactorialAssign({sequenceSet}, {ones(cfg.n.sequence,1)}, idxDesign, seqMinLength(:,c), seqLength, sequenceDistIdeal, [sequenceVal max(sequenceVal)], sequenceRestriction(c), maxCondRepetition, maxWhileLoopIter);

    else

      % ignore the factorial design, assign random
      sequenceSubset = SelectSeqLength(sequenceSet,sequenceDistIdeal,nSequenceRequired,sequenceVal,[],sequenceRestriction(c));
      % randomly permute, but prevent too many repetitions (maxRepetitions = 3)
      while true
        sequenceSubset = sequenceSubset(randperm(nSequenceRequired));
        if max(diff(find(diff([-Inf; sequenceSubset; Inf])))) <= maxCondRepetition, break; end
      end
      % assign the subset sequences to the pulses
      seqLength(seqMinLength(:,c)) = sequenceSubset;

    end

    % remove the assigned subset from the available set
    sequenceSet = RemoveSubset(sequenceSet, sequenceSubset);

  end


  %% assign sequence lengths to remaining conditions
  %----------------------------------------

  % dividing remaining sequences, in a factorial order
  idxFact = {ones(cfg.n.sequence,1)};
  idxDesign = [seqCueStaySwitch seqPulseType seqCueSide seqSideStaySwitch];
  seqLength = FactorialAssign({sequenceSet}, idxFact, idxDesign, seqLength==0, seqLength, sequenceDistIdeal, [sequenceVal max(sequenceVal)], [], maxCondRepetition, maxWhileLoopIter);

  % the length of the extra sequence at the end (without a pulse) is fixed
  seqLength(cfg.n.sequence) = 6;
  cfg.n.trial = sum(seqLength);


  %% assign pulses to stay sequences
  %----------------------------------------

  % update the trial number distribution with respect to the realised
  % sequence length distribution
  if isequal(numDistIdeal,sequenceDistIdeal)
    numDistIdeal = histcounts(seqLength(seqCueSwitch),[sequenceVal max(sequenceVal)]);
    numDistIdeal = numDistIdeal / sum(numDistIdeal);
  end

  % for each stay sequence, find the available trial numbers, then assign
  % from the most strict to the most free
  % first define the onset of the available trial window
  idxOn = zeros(cfg.n.sequence,1);
  % all stay pulses need to occur at a safe distance from the switch
  %pulseStayAfterStay = pulseCueStaySwitch == 1 & [2; pulseCueStaySwitch(1:end-1)] == 1;
  idxOn(seqCueStay) = max(min(sequenceVal), 1 + 1 + cfg.n.afterSwitch);
  % stay pulses that follow a switch pulse should keep a safe distance
  seqStayAfterSwitch = seqCueStay & [true; seqCueSwitch(1:end-1)];
  idxOn(seqStayAfterSwitch) = max(min(sequenceVal), 1 + 1 + max(cfg.n.aroundPulse,cfg.n.afterSwitch));
  % then define the offset of the available trial window
  idxOff = -ones(cfg.n.sequence,1);
  % all stay pulses are limited by the sequence length
  idxOff(seqCueStay) = seqLength(seqCueStay);

  % define a secondary trial window for stay pulses followed by switch
  idxOnExtra = zeros(cfg.n.sequence,1);
  idxOffExtra = -ones(cfg.n.sequence,1);
  flgMoreStayOptions = true;
  if flgMoreStayOptions
    % identify stay pulses that are followed by a switch pulse
    seqStayBeforeSwitch = seqCueStay & [seqCueSwitch(2:end); false];
    seqSwitchAfterStay = seqCueSwitch & [false; seqCueStay(1:end-1)];
    if sum(seqStayBeforeSwitch) ~= sum(seqSwitchAfterStay), error('oh oh, something is wrong'); end
    % find the secondary trial window onset
    idxOnExtra(seqStayBeforeSwitch) = max(min(sequenceVal), 1 + 1 + cfg.n.afterSwitch);
    % and the secondary trial window offset
    idxOffExtra(seqStayBeforeSwitch) = seqLength(seqSwitchAfterStay) - cfg.n.aroundPulse;
    % ignore those secondary windows that are not sufficiently large 
    idxIgnoreExtra = (idxOffExtra - idxOnExtra + 1) <=0;
    idxOnExtra(idxIgnoreExtra) = 0;
    idxOffExtra(idxIgnoreExtra) = -1;
  end

  % define the trial windows
  seqWin = arrayfun(@(a,b) a:b,idxOn,idxOff,'UniformOutput',false);
  seqWinExtra = arrayfun(@(a,b) a:b,idxOnExtra,idxOffExtra,'UniformOutput',false);

  % count the number of available trial numbers
  seqWinNum = cellfun(@(a,b) unique([a b]),seqWin,seqWinExtra,'UniformOutput',false);
  nSeqWinNum = cellfun(@numel,seqWinNum);

  % check if all stay sequences have sufficient trials available
  if any(nSeqWinNum(seqCueStay)<1)
    errstr = sprintf('some stay sequences are not long enough: ');
    errstr = [errstr sprintf('%d\t',find(nSeqWinNum(seqCueStay)<1))];
    error(errstr);
  end

  % create a set of stay pulse trial numbers matching the switch sequences
  stayNumSet = seqLength(seqCueSwitch);
  seqNum = zeros(cfg.n.sequence,1);

  % assign stay pulses to the most restricted sequences first
  for c = 1:max(nSeqWinNum)
    % identify the restricted stay sequences
    idxStayRestricted = find(nSeqWinNum==c & seqCueStay);
    nToBeAssigned = numel(idxStayRestricted);
    if nToBeAssigned == 0, continue; end

    % retrieve trial numbers
    stayNumAvailable = cell2mat(seqWinNum(idxStayRestricted));
    seqLengthAvailable = seqLength(idxStayRestricted);

    % select from available trial numbers
    if c == 1
      stayNumSubset = stayNumAvailable;
    else
      % count current distribution of already assigned trial numbers
      val = [sequenceVal max(sequenceVal)];
      stayNumDistCurr = histcounts(seqNum(seqNum>0),val);

      % select from available trial numbers according to ideal distribution
      stayNumSelect = SelectSeqLength(stayNumAvailable(:),numDistIdeal,nToBeAssigned,stayNumDistCurr,val,[],'silent');

      % match the subset selection to the available sequences
      stayNumSubset = zeros(nToBeAssigned,1);
      idxToBeAssigned = true(nToBeAssigned,1);
      while ~isempty(stayNumSelect)
        % first find the unique entries
        numValSelect = unique(stayNumSelect)';
        % compare the selected and the available trial numbers
        numAvailableCount = histcounts(stayNumAvailable(idxToBeAssigned,:),[numValSelect max(numValSelect)]);
        numSelectCount = histcounts(stayNumSelect,[numValSelect max(numValSelect)]);
        % assign the tightest match first
        [match,idxVal] = min(numAvailableCount - numSelectCount);
        num = numValSelect(idxVal);
        idxPulse = any(stayNumAvailable==num,2) & idxToBeAssigned;

        % return quickly if only one assignment is possible
        if match == 0
          % simple one-on-one assigment
          stayNumSubset(idxPulse) = num;

        else

          % bias pulse assignment to the middle of a sequence
          idxPulse = find(idxPulse);
          idxPulseMiddle = [];
          if flgBiasStayToSeqMiddle
            % check which pulses are available in the middle of a sequence
            idxPulseMiddle = intersect(find(seqLengthAvailable ~= num),idxPulse);
            % try to assign the pulses in the middle of a sequence first
            if numel(idxPulseMiddle) <= numSelectCount(idxVal)
              idxPulse = setdiff(idxPulse,idxPulseMiddle);
            else
              idxPulse = idxPulseMiddle;
              idxPulseMiddle = [];
            end
          end
          nLeftToAssign = numSelectCount(idxVal)-numel(idxPulseMiddle);

          % bias pulse assignment to those that have few already assigned
          idxPulseMinAssigned = [];
          if nLeftToAssign>0 && flgBiasStayToNotAssigned
            % find how many of this trial number as already been assigned
            % (in absolute or relative terms)
            nAssignedNum = zeros(numel(idxPulse),1);
            for d = 1:numel(idxPulse)
              %idxSameCond = all(pulseCond == pulseCond(idxStayRestricted(idxPulse(d)),:),2);
              idxSameCond = all(pulseCond == repmat(pulseCond(idxStayRestricted(idxPulse(d)),:),cfg.n.sequence,1),2);
              if strcmpi(flgBiasStayToNotAssignedMethod,'relative')
                condDist = histcounts(seqNum(idxSameCond),[sequenceVal max(sequenceVal)]);
                %condDist = condDist/sum(condDist);
                condDist = condDist/mean(condDist(condDist>0));
                condDistIdeal = sequenceDistIdeal/sum(sequenceDistIdeal(condDist>0));
                nAssignedNum(d) = condDistIdeal(sequenceVal==num) - condDist(sequenceVal==num);
              else
                nAssignedNum(d) = sum(seqNum(idxSameCond)==num);
              end
            end
            % sort the available pulses according to the number assigned
            [nAssignedNum,idxSort] = sort(nAssignedNum);
            minAssignedNum = nAssignedNum(nLeftToAssign);
            idxPulseMinAssigned = idxPulse(idxSort(nAssignedNum<minAssignedNum));
            idxPulse = idxPulse(idxSort(nAssignedNum<=minAssignedNum));
            idxPulse = setdiff(idxPulse,idxPulseMinAssigned);
          end

          % randomly assign remaining pulses
          idxPulse = [idxPulseMiddle; idxPulseMinAssigned; idxPulse(randperm(numel(idxPulse)))];
          idxPulse = idxPulse(1:numSelectCount(idxVal));
          stayNumSubset(idxPulse) = num;

        end

        % remove current trial number from selected set
        stayNumSelect(stayNumSelect==num) = [];
        idxToBeAssigned(idxPulse) = false;

      end
    end

    % assign trial numbers
    seqNum(idxStayRestricted) = stayNumSubset;

    % remove the assigned trial numbers from the available set
    stayNumSet = RemoveSubset(stayNumSet, stayNumSubset);

  end

  % check if all stay pulses have been assigned
  if any(seqNum(seqCueStay) == 0)
    error('not all stay pulses seem to have been assigned correctly');
  end

  % add the pulse numbers (1) for the switch pulses
  seqNum(seqCueSwitch) = 1;
  % to convert the sequence number to a trial number, please note that the
  % switch pulse occurs on the first trial of the *next* sequence
  seqNumForTrialIndexing = seqNum;
  seqNumForTrialIndexing(seqCueSwitch) = seqLength(seqCueSwitch) + 1;

  % if the requested trial number for the stay pulse is also available in the
  % folllowing switch sequence, take that one instead for the trial indexing
  seqWinExtraSelect = cellfun(@ismember,num2cell(seqNum),seqWinExtra);
  seqNumForTrialIndexing(seqWinExtraSelect) = seqLength(seqWinExtraSelect) + seqNum(seqWinExtraSelect);


  %% convert sequence specs to trial specs
  %----------------------------------------

  % number the trials relative to the whole session
  trialNumOverall = (1:cfg.n.trial)';

  % number the sequences
  trialSeqNum = arrayfun(@(a,b) repmat(a,1,b), 1:cfg.n.sequence, seqLength','UniformOutput',false);
  trialSeqNum = [trialSeqNum{:}]';

  % number the trials within each sequence
  trialNumInSeq = arrayfun(@(a) 1:a, seqLength','UniformOutput',false);
  trialNumInSeq = [trialNumInSeq{:}]';
  idxSeqStart = find(trialNumInSeq==1);

  % define trials as cue stay or switch
  trialCueStaySwitch = ones(cfg.n.trial,1);
  trialCueStaySwitch(trialNumInSeq==1) = 2;

  % assign the pulses to the trial numbers
  trialPulse = zeros(cfg.n.trial,1);
  trialPulse(idxSeqStart(1:cfg.n.pulse) + seqNumForTrialIndexing(1:cfg.n.pulse) - 1) = 1;

  % assign cue colour
  trialCueColour = arrayfun(@(a,b) repmat(a,1,b), seqCueColour, seqLength','UniformOutput',false);
  trialCueColour = [trialCueColour{:}]';

  % assign cue side on the pulse trials
  trialCueSide = zeros(cfg.n.trial,1);
  trialCueSide(trialPulse>0) = seqCueSide(seqCueSide>0);

  % assign the trial preceding the pulse, based on the side stay/switch
  trialSideStaySwitch = zeros(cfg.n.trial,1);
  trialSideStaySwitch(trialPulse>0) = seqSideStaySwitch(seqSideStaySwitch>0);
  idxSideStay = find(trialSideStaySwitch == 1);
  idxSideSwitch = find(trialSideStaySwitch == 2);
  trialCueSide(idxSideStay-1) = trialCueSide(idxSideStay);
  trialCueSide(idxSideSwitch-1) = 1+cfg.n.side-trialCueSide(idxSideSwitch);
  % potential to go one further back
  %trialCueSide(idxSideStay-2) = trialCueSide(idxSideStay);
  %trialCueSide(idxSideSwitch-2) = 1+cfg.n.side-trialCueSide(idxSideSwitch);

  % create a set of left and right cue sides
  sideSet =  mod((1:cfg.n.trial)', 2) + 1;
  % with one random assigment when the total trial number is odd
  if mod(cfg.n.trial,2)
    sideSet(end) = randi([1 2]);
  end

  % randomly assign the remaining trials to left or right, per block
  idxBlock = round(1:(cfg.n.trial/cfg.n.pulseCondCell):cfg.n.trial);
  idxBlock(cfg.n.pulseCondCell+1) = cfg.n.trial;
  cIter = 1;
  flgCheck = false;
  while ~flgCheck
    for c = 1:cfg.n.pulseCondCell
      % identify which trials this "block" occupies
      idxTrial = false(cfg.n.trial,1);
      idxTrial(idxBlock(c):idxBlock(c+1)) = true;
      % create a subset of cue sides
      sideSubset = sideSet(idxTrial);
      % remove already assigned sides
      sideSetRemove = trialCueSide(idxTrial & trialCueSide>0);
      sideSubset = RemoveSubset(sideSubset, sideSetRemove);
      % identify the trials to be assigned
      idxToAssign = idxTrial & trialCueSide==0;
      % re-do the randomization until it matches the criteria
      while true
        % randomly permute conditions
        trialCueSide(idxToAssign) = sideSubset(randperm(numel(sideSubset)));
        % check for repetitions and break if the criteria are matched
        if max(diff(find(diff([-Inf; trialCueSide(1:idxBlock(c+1)); Inf])))) <= maxSideRepetition, flgCheck = true; end
        if flgCheck || cIter > maxWhileLoopIter, break; end
        cIter = cIter + 1;
      end
    end
    if flgCheck, break; end
  end

  % determine all side stay/switches based on the full specs
  trialSideStaySwitch = 1 + abs(diff([0; trialCueSide]));

  % determine flanker colours based on cue colour and side
  trialFlankerLeft = zeros(cfg.n.trial,1);
  % copy the cue colour when the cue points to the left
  trialFlankerLeft(trialCueSide==1) = trialCueColour(trialCueSide==1);
  % invert the cue colour when the cue points to the right
  trialFlankerLeft(trialCueSide==2) = 3-trialCueColour(trialCueSide==2);
  % invert the left flanker colour to the right flanker
  trialFlankerRight = 3-trialFlankerLeft;

  % set the type of TMS pulse
  trialPulseType = zeros(cfg.n.trial,1);
  trialPulseType(trialPulse>0) = seqPulseType(seqPulseType>0);


  %% logging of pre-set variables
  %------------------------
  % pre-allocate memory for the logfile
  log.data = zeros(cfg.n.trial,length(log.varName));
  % general
  log = LogSetColumn(log, 'trialNumber', trialNumOverall);
  log = LogSetColumn(log, 'sequenceNumber', trialSeqNum);
  log = LogSetColumn(log, 'sequenceTrial', trialNumInSeq);
  log = LogSetColumn(log, 'break', zeros(cfg.n.trial,1));
  % flanker
  log = LogSetColumn(log, 'flankerLeft', trialFlankerLeft);
  log = LogSetColumn(log, 'flankerRight', trialFlankerRight);
  % cue
  log = LogSetColumn(log, 'cueColour', trialCueColour);
  log = LogSetColumn(log, 'cueSide', trialCueSide);
  log = LogSetColumn(log, 'cueStaySwitch', trialCueStaySwitch);
  log = LogSetColumn(log, 'sideStaySwitch', trialSideStaySwitch);
  % TMS pulse
  log = LogSetColumn(log, 'tmsPulse', trialPulseType);


  %% assign breaks
  %----------------------------------------

  % identify ideal places for breaks in between blocks
  idxBreak = 1:(cfg.n.trial/cfg.n.block):cfg.n.trial;
  idxBreakAvailable = idxSeqStart(seqNumForTrialIndexing > cfg.n.afterBreak);
  % match the ideal places to the available places
  for c = 1:numel(idxBreak)
    idxBreak(c) = idxBreakAvailable(nearest(idxBreakAvailable,idxBreak(c)));
  end

  % check that the breaks are assigned correctly
  if idxBreak(1) ~= 1
    error('something went wrong with assigning the breaks');
  end

  % copy the trials before and after a switch
  idxBlockStart = idxBreak';
  idxBlockEnd = [idxBreak(2:end) cfg.n.trial]';
  idxNew = arrayfun(@(a,b) a:b,idxBlockStart,idxBlockEnd,'UniformOutput',false);
  idxNew = [idxNew{:}]';

  % update the trial specs and the block indices
  log.data = log.data(idxNew,:);
  idxBlockStart = idxBlockStart + (0:(cfg.n.block-1))';
  % add the breaks at the right places
  log = LogSet(log, idxBlockStart, 'break', 1);
  % and make sure these trials are neither stay nor switch, and no TMS
  log = LogSet(log, idxBlockStart, 'cueStaySwitch', 0);
  log = LogSet(log, idxBlockStart, 'sideStaySwitch', 0);
  log = LogSet(log, idxBlockStart, 'tmsPulse', 0);

  % retrieve specs from current solution
  trialNumInSeq = LogGetColumn(log,'sequenceTrial');
  trialCueStaySwitch = LogGetColumn(log,'cueStaySwitch');
  trialPulse = LogGetColumn(log,'tmsPulse');
  trialCueSide = LogGetColumn(log,'cueSide');
  trialSideStaySwitch = LogGetColumn(log,'sideStaySwitch');
  
  % check how well the realised distribution matches the ideal one
  bin = [sequenceVal max(sequenceVal)];
  rmse = [];
  rmse.cueStaySwitch = CompareCondDist(trialNumInSeq,trialCueStaySwitch,trialPulse,trialCueStaySwitch,sequenceDistIdeal,bin);
  rmse.pulseType = CompareCondDist(trialNumInSeq,trialPulse,trialPulse,trialCueStaySwitch,sequenceDistIdeal,bin);
  rmse.side = CompareCondDist(trialNumInSeq,trialCueSide,trialPulse,trialCueStaySwitch,sequenceDistIdeal,bin);
  rmse.sideStaySwitch = CompareCondDist(trialNumInSeq,trialSideStaySwitch,trialPulse,trialCueStaySwitch,sequenceDistIdeal,bin);
  
  % check for probability of switch trial following TMS
  idx = trialPulse>0 & trialCueStaySwitch==1;
  idx = [false; idx(1:end-1)];
  rmse.probSwitchAfterStayPulse = mean(trialCueStaySwitch(idx)==2);
  
  % assign weigths to the different error terms
  rmse.all = [rmse.cueStaySwitch, rmse.pulseType, rmse.side, rmse.sideStaySwitch, rmse.probSwitchAfterStayPulse];
  rmse.weights = [10 5 3 1 5];
  rmse.solution = mean(rmse.all .* rmse.weights);
  
  % store best solution
  if rmse.solution < bestSolution
    bestSolution = rmse.solution;
    bestRmse = rmse;
    bestLog = log;
    bestIter = iter;
  end

end

% report on best solution
fprintf(' done\n')
fprintf('best solution found in iteration %d out of %d:\n',bestIter,maxIter);
fprintf('RMSE of cueStaySwitch distribution: %.4f\n',bestRmse.cueStaySwitch);
fprintf('RMSE of pulseType distribution: %.4f\n',bestRmse.pulseType);
fprintf('RMSE of cueSide distribution: %.4f\n',bestRmse.side);
fprintf('RMSE of sideStaySwitch distribution: %.4f\n',bestRmse.sideStaySwitch);
fprintf('probability of switch after stay (TMS trials): %.4f\n',bestRmse.probSwitchAfterStayPulse);
log = bestLog;


% when testing the condition randomization report on the best solution
if cfg.flg.testcond

  %% report
  %----------------------------------------
  % retrieve specs from best solution
  trialNumInSeq = LogGetColumn(log,'sequenceTrial');
  trialCueStaySwitch = LogGetColumn(log,'cueStaySwitch');
  trialPulse = LogGetColumn(log,'tmsPulse');
  trialCueSide = LogGetColumn(log,'cueSide');
  trialSideStaySwitch = LogGetColumn(log,'sideStaySwitch');

  figure(1);
  subplot(5,2,1);
  histogram(trialNumInSeq(trialNumInSeq>=min(sequenceVal) & trialCueStaySwitch==1));
  title('trialNumInSeq for cueStay (all)');

  subplot(5,2,2);
  histogram(trialNumInSeq(find(trialCueStaySwitch==2)-1));
  title('trialNumInSeq for cueSwitch (all)');

  subplot(5,2,3);
  histogram(trialNumInSeq(trialPulse>0 & trialCueStaySwitch==1));
  title('trialNumInSeq for cueStay (TMS)');

  subplot(5,2,4);
  histogram(trialNumInSeq(find(trialPulse>0 & trialCueStaySwitch==2)-1));
  title('trialNumInSeq for cueSwitch (TMS)');

  subplot(5,2,5);
  histogram([trialNumInSeq(trialCueStaySwitch==1 & trialPulse==1); trialNumInSeq(find(trialCueStaySwitch==2 & trialPulse==1)-1)]);
  title('trialNumInSeq for single-pulse TMS');

  subplot(5,2,6);
  histogram([trialNumInSeq(trialCueStaySwitch==1 & trialPulse==2); trialNumInSeq(find(trialCueStaySwitch==2 & trialPulse==2)-1)]);
  title('trialNumInSeq for paired-pulse TMS');

  subplot(5,2,7);
  histogram([trialNumInSeq(trialPulse>0 & trialCueStaySwitch==1 & trialCueSide==1); trialNumInSeq(find(trialPulse>0 & trialCueStaySwitch==2 & trialCueSide==1)-1)]);
  title('trialNumInSeq for left hand');

  subplot(5,2,8);
  histogram([trialNumInSeq(trialPulse>0 & trialCueStaySwitch==1 & trialCueSide==2); trialNumInSeq(find(trialPulse>0 & trialCueStaySwitch==2 & trialCueSide==2)-1)]);
  title('trialNumInSeq for right hand');

  subplot(5,2,9);
  histogram([trialNumInSeq(trialPulse>0 & trialCueStaySwitch==1 & trialSideStaySwitch==1); trialNumInSeq(find(trialPulse>0 & trialCueStaySwitch==2 & trialSideStaySwitch==1)-1)]);
  title('trialNumInSeq for hand stay');

  subplot(5,2,10);
  histogram([trialNumInSeq(trialPulse>0 & trialCueStaySwitch==1 & trialSideStaySwitch==2); trialNumInSeq(find(trialPulse>0 & trialCueStaySwitch==2 & trialSideStaySwitch==2)-1)]);
  title('trialNumInSeq for hand switch');

  % check for probability of switch trial (considering all trials)
  %idx = LogGetColumn(log,'cueStaySwitch')==1;
  %idx = [false; idx(1:end-1)];
  %probSwitchAfterStayAll = mean(LogGet(log,idx,'cueStaySwitch')==2);
  %fprintf('probability of switch after stay (all trials): %.4f\n',probSwitchAfterStayAll);
  
end


function aSubset = SelectSeqLength(aSet, distIdeal, nRequired, distCurr, val, minVal, flgVerbose)
% select a subset of sequence lengths based on a given distribution
if nargin<4, distCurr = []; end
if nargin<5 || isempty(val), val = unique(aSet)'; end
if nargin<5 || isempty(minVal), minVal = 0; end
if nargin<6, flgVerbose = 'verbose'; end
val = unique(val);

% try to return quickly, if possible
if nRequired == 0
  aSubset = []; return
elseif numel(aSet) == nRequired
  aSubset = aSet;
  if isequal(flgVerbose,'verbose')
    warning('the requested number of sequences is equal to the number that are available'); 
  end
  return
elseif numel(aSet) < nRequired
  error('more sequences are requested (%d) than are available (%d)',nRequired,numel(aSet));
end

% define an initial subset based on the minimum sequence length
idxSubset = val >= minVal;
valSubset = val(idxSubset);
aSubset = aSet(aSet >= minVal);
countSubset = histcounts(aSubset,[valSubset max(valSubset)]);

% add the current distribution (if it exists)
if isempty(distCurr), distCurr = zeros(size(val)); end
distCurrSubset = distCurr(idxSubset);
countSubset = countSubset + distCurrSubset;
nRequired = nRequired + sum(distCurrSubset);

% define an ideal distribution for the subset of sequence lengths
distSubsetIdeal = distIdeal(idxSubset);
distSubsetIdeal = distSubsetIdeal./sum(distSubsetIdeal);

% apply this to the required number of sequence lengths
distSubset = distSubsetIdeal .* nRequired;

% make sure these are integers and add up to the required number
[~,seqLengthSubsetDistAdd] = sort(mod(distSubset,1).*distSubsetIdeal,'descend');
distSubset = floor(distSubset);
idxAddOne = seqLengthSubsetDistAdd(1:(nRequired-sum(distSubset)));
distSubset(idxAddOne) = distSubset(idxAddOne) + 1;

% test if requested subset distribution is achievable
if any(distSubset>countSubset)
  if isequal(flgVerbose,'verbose')
    fprintf('sequence length:\t'); fprintf('\t%d',valSubset); fprintf('\n');
    fprintf('available distribution:\t'); fprintf('\t%d',countSubset-distCurrSubset); fprintf('\n');
    fprintf('requested distribution:\t'); fprintf('\t%d',distSubset-distCurrSubset); fprintf('\n');
  end
  % find which sequence lengths to remove
  idxMismatch = distSubset - countSubset;
  distSubset = distSubset - max(0,idxMismatch);
  % keep adding one back (according to distribution)
  while sum(distSubset) < nRequired
    % compare the current distribution to the ideal
    [~,idxAddOne] = sort((distSubsetIdeal .* nRequired) - distSubset,'descend');
    % ignore sequence lengths that are no longer available 
    idxAddOne(ismember(idxAddOne,find(idxMismatch>=0))) = [];
    % break if no sequence lengths are left
    if isempty(idxAddOne), break; end
    % add as much as we can in this round
    idxAddOne = idxAddOne(1:min(numel(idxAddOne),nRequired-sum(distSubset)));
    distSubset(idxAddOne) = distSubset(idxAddOne) + 1;
    % update the mismatch counter
    idxMismatch = distSubset - countSubset;
  end
  if isequal(flgVerbose,'verbose')
    fprintf('realised distribution:\t'); fprintf('\t%d',distSubset-distCurrSubset); fprintf('\n');
    warning('the requested distribution of sequence lengths could not be drawn from the available set');
  end
end

% check if it doesn't conflict with the current distribution
if any(distSubset<distCurrSubset)
  if isequal(flgVerbose,'verbose')
    fprintf('sequence length:\t'); fprintf('\t%d',valSubset); fprintf('\n');
    fprintf('current distribution:\t'); fprintf('\t%d',distCurrSubset); fprintf('\n');
    fprintf('requested distribution:\t'); fprintf('\t%d',distSubset); fprintf('\n');
  end
  % find which sequence lengths to remove
  idxMismatch = distCurrSubset - distSubset;
  distSubset = distSubset + max(0,idxMismatch);
  % keep removing one (according to distribution)
  while sum(distSubset) > nRequired
    % compare the current distribution to the ideal
    [~,idxRemoveOne] = sort((distSubsetIdeal .* nRequired) - distSubset,'ascend');
    % ignore sequence lengths that are no longer available 
    idxRemoveOne(ismember(idxRemoveOne,find(idxMismatch>=0))) = [];
    % break if no sequence lengths are left
    if isempty(idxRemoveOne), break; end
    % add as much as we can in this round
    idxRemoveOne = idxRemoveOne(1:min(numel(idxRemoveOne),sum(distSubset)-nRequired));
    distSubset(idxRemoveOne) = distSubset(idxRemoveOne) - 1;
    % update the mismatch counter
    idxMismatch = distCurrSubset - distSubset;
  end
  if isequal(flgVerbose,'verbose')
    fprintf('realised distribution:\t'); fprintf('\t%d',distSubset-distCurrSubset); fprintf('\n');
    warning('the requested distribution of sequence lengths could not be drawn from the available set');
  end
end

% remove the current distribution from the realised distribution
distSubset = distSubset - distCurrSubset;
distSubset = max(distSubset,0);
nRequired = nRequired - sum(distCurrSubset);

% final check
if sum(distSubset) ~= nRequired
  error('the number of realised sequence lengths (%d) does not match the number of requested lengths (%d)',sum(distSubset),nRequired);
end

% pick sequence lengths from subset according to distribution
aSubset = arrayfun(@(a,b) repmat(a,1,b),valSubset,distSubset,'UniformOutput',false);
aSubset = [aSubset{:}]';



function aSet = RemoveSubset(aSet, aSubset)
% remove the assigned subset from the available set

% initialise
idx = true(size(aSet));
% identify uniqe values in the subset and remove
val = unique(aSubset);
for d = 1:numel(val)
  % count number of instances in the subset
  n = sum(aSubset==val(d));
  % mark the value from the subset in the full set
  idx(find(aSet==val(d),n,'first')) = false;
end
% remove subset from set
aSet = aSet(idx);


function [seqLength, seqSelect] = FactorialAssign(setFact, idxFact, idxDesign, idxToBeAssigned, seqLength, distIdeal, distVal, minVal, maxRepetitions, maxIter)
% assign a set recursively according to the factorial design
if isempty(idxToBeAssigned), idxToBeAssigned = seqLength==0; end
if isempty(minVal), minVal = 0; end

% ensure criitical input are cell arrays
if ~iscell(setFact), setFact = {setFact}; end
if ~iscell(idxFact), idxFact = {idxFact}; end
if ~iscell(distIdeal), distIdeal = {distIdeal}; end

% dividing sequences, in a factorial order
for d = 1:size(idxDesign,2)
  
  % all factors have two conditions
  nCond = 2;
  
  % assign sequence length first for switch sequences, then for stay
  % assign in a random order for the remaining conditions
  if d == 1
    cond = nCond:-1:1;
  else
    cond = randperm(nCond);
  end
  
  % ensure idealDist matches the number of parents
  nParents = numel(setFact);
  if ~size(distIdeal,1)==1, distIdeal = repmat(distIdeal,nParents,1); end
  
  % split the parent sets one by one
  setChild = cell(nCond*nParents,1);
  idxChild = cell(nCond*nParents,1);
  distChild = cell(nCond*nParents,1);
  for p = 1:nParents
    idx = (p-1)*nCond + (1:nCond);
    [setChild(idx), idxChild(idx), distChild(idx)] = FactorialSplit(setFact{p}, idxFact{p}, idxDesign(:,d), idxToBeAssigned, seqLength, distIdeal(p,:), distVal, minVal, cond);
  end
  
  % update for the next recursion
  idxFact = idxChild;
  setFact = setChild;
  distIdeal = distChild;
  
end

% collect all selected sets into one
seqSelect = vertcat(setFact{:});

% randomly assign sequence lengths according to factorial grouping, repeat
% permutation until criteria are fullfilled
cIter = 1;
flgCheck = false;
while ~flgCheck
  for d = 1:size(setFact,1)
    %idx = seqLength==0 & idxFact{d};
    idx = idxToBeAssigned & idxFact{d};
    while true
      seqLength(idx) = setFact{d}(randperm(numel(setFact{d})));
      % prevent too many repetitions (maxRepetitions = 3)
      if max(diff(find(diff([-Inf; seqLength(seqLength>0); Inf])))) <= maxRepetitions, flgCheck = true; end
      if flgCheck || cIter > maxIter, break; end
      cIter = cIter + 1;
    end
  end
  if flgCheck, break; end
end


function [setChild, idxChild, distChild] = FactorialSplit(setParent, idxParent, design, idxToBeAssigned, alreadyAssigned, idealDist, val, minVal, cond)
% split a set recursively according to a factorial design
if nargin < 8 || isempty(minVal), minVal = 0; end
if nargin < 9 || isempty(cond), cond = unique(design(design>0)); end

% number of conditions
nCond = numel(cond);

% ensure idealDist matched the number of conditions
if ~iscell(idealDist), idealDist = {idealDist}; end
if size(idealDist,2)<nCond
  distChild = repmat(idealDist,1,nCond);
else
  distChild = idealDist;
end

% randomise the order in which the conditions are assigned
setChild = cell(nCond,1);
idxChild = cell(nCond,1);
for c = cond
  % retrieve indices of the trials that match the factorial condition
  idxChild{c} = idxParent & design==c;
  %nToBeAssigned = sum(idxChild{c} & alreadyAssigned==0);
  nToBeAssigned = sum(idxChild{c} & idxToBeAssigned);
  % retrieve current distribution
  currDist = histcounts(alreadyAssigned(idxChild{c} & alreadyAssigned>0),val);
  % select an appropriate subset
  setChild{c} = SelectSeqLength(setParent, distChild{c}, nToBeAssigned, currDist, val, minVal, 'silent');
  % remove the assigned subset for the parent set
  setParent = RemoveSubset(setParent, setChild{c});
  % retrieve the realised distribution
  if size(idealDist,2)<nCond
    distChild{c} = histcounts(setChild{c},val);
    distChild{c} = distChild{c} + currDist;
    distChild{c} = distChild{c}/sum(distChild{c});
  end
end


function rmse = CompareCondDist(data,idxCond,idxIncl,idxSwitch,idealDist,bin)
% compare the realised distribution with a reference, returning the
% mean-squared-error
idealDist = idealDist/sum(idealDist);

condList = unique(idxCond(idxCond>0));
nCond = numel(condList);
rmse = zeros(1,nCond);
for c = 1:nCond
  if isempty(idxSwitch)
    dataSelect = data(idxIncl>0 & idxCond==condList(c));
  else
    dataSelect = [data(idxIncl>0 & idxSwitch==1 & idxCond==condList(c)); data(find(idxIncl>0 & idxSwitch==2 & idxCond==condList(c))-1)];
  end
  condDist = histcounts(dataSelect,bin);
  condDist = condDist/sum(condDist);
  rmse(c) = sqrt(mean((100*(condDist - idealDist)).^2));
end
rmse = mean(rmse);


function [cfg, log] = PrepareInstruction(cfg, log)
%% PrepareInstruction
%--------------------
% return quickly when no instructions are needed
if ~strcmpi(cfg.sessionName,'baseline')
  cfg.n.instr.trial = 0;
  return
end

% start the practice trials from the beginning
cfg.instr.stage = 1;

%% set trial specs for instruction trials
%----------------------------------------

% number the trials relative to the whole session
cfg.n.instr.trialdummy = 5;
cfg.n.instr.trial = 30;
% these numbers are stored with a negative value to make them distinct from
% the trials in the real session
trialNumOverall = -(1:cfg.n.instr.trial)';

% number the sequences
seqLength = [7 5 5 7 6]';
cfg.n.instr.sequence = numel(seqLength);
trialSeqNum = arrayfun(@(a,b) repmat(a,1,b), 1:cfg.n.instr.sequence, seqLength','UniformOutput',false);
trialSeqNum = [trialSeqNum{:}]';

% number the trials within each sequence
trialNumInSeq = arrayfun(@(a) 1:a, seqLength','UniformOutput',false);
trialNumInSeq = [trialNumInSeq{:}]';

% define trials as cue stay or switch
trialCueStaySwitch = ones(cfg.n.instr.trial,1);
trialCueStaySwitch(trialNumInSeq==1) = 2;

% assign the pulses to the trial numbers
idxPulse = [4 8 14 18 25 30];
trialPulse = zeros(cfg.n.instr.trial,1);
trialPulse(idxPulse) = 1;

% assign cue colour
seqCueColour = [1 2 1 2 1];
trialCueColour = arrayfun(@(a,b) repmat(a,1,b), seqCueColour, seqLength','UniformOutput',false);
trialCueColour = [trialCueColour{:}]';

% assign cue side
trialCueSide = [1 2 2 1 1 2 2 2 1 2 2 1 1 2 2 1 2 1 1 1 2 1 2 1 1 1 2 1 2 2]';

% determine side stay/switches
trialSideStaySwitch = 1 + abs(diff([0; trialCueSide]));

% determine flanker colours based on cue colour and side
trialFlankerLeft = zeros(cfg.n.instr.trial,1);
% copy the cue colour when the cue points to the left
trialFlankerLeft(trialCueSide==1) = trialCueColour(trialCueSide==1);
% invert the cue colour when the cue points to the right
trialFlankerLeft(trialCueSide==2) = 3-trialCueColour(trialCueSide==2);
% invert the left flanker colour to the right flanker
trialFlankerRight = 3-trialFlankerLeft;

% set the type of TMS pulse
trialPulseType = zeros(cfg.n.instr.trial,1);
trialPulseType(trialPulse>0) = [1 2 1 2 1 2];

% set the instruction breaks
trialBreak = zeros(cfg.n.instr.trial,1);
trialBreak([1 cfg.n.instr.trialdummy+1]) = 1;


%% store in a log structure
%----------------------------------------

% pre-allocate memory for the instruction logfile
instr = log;
instr.data = zeros(cfg.n.instr.trial,length(instr.varName));
% general
instr = LogSetColumn(instr, 'trialNumber', trialNumOverall);
instr = LogSetColumn(instr, 'sequenceNumber', trialSeqNum);
instr = LogSetColumn(instr, 'sequenceTrial', trialNumInSeq);
instr = LogSetColumn(instr, 'break', trialBreak);
% flanker
instr = LogSetColumn(instr, 'flankerLeft', trialFlankerLeft);
instr = LogSetColumn(instr, 'flankerRight', trialFlankerRight);
% cue
instr = LogSetColumn(instr, 'cueColour', trialCueColour);
instr = LogSetColumn(instr, 'cueSide', trialCueSide);
instr = LogSetColumn(instr, 'cueStaySwitch', trialCueStaySwitch);
instr = LogSetColumn(instr, 'sideStaySwitch', trialSideStaySwitch);
% TMS pulse
instr = LogSetColumn(instr, 'tmsPulse', trialPulseType);

% concatenate the instructions and the real session
log.data = [instr.data; log.data];


function cfg = InitDur(cfg)
%% InitDur
%------------------------
% random duration of the inter-trial-interval
cfg.dur.interval = 1;
%ITI = [1 2];
%cfg.dur.interval = min(ITI) + diff(ITI).*rand(1,cfg.n.trial);

% duration of the flankers before the cue presentation
flankerDur = [0.45 0.6];
cfg.dur.flanker = min(flankerDur) + diff(flankerDur).*rand(1, cfg.n.trial + cfg.n.instr.trial);

% time, interval, and duration of TMS pulse
cfg.dur.tmsPulse = 0.175;
cfg.dur.pulseWidth = 0.002;
cfg.dur.IPI = 0.006;

% maximum reaction time allowed
cfg.dur.maxRT = Inf;
if cfg.dur.maxRT < 10
  warning('The maximum reaction time allowed (%.1f) seems quite short. Are you sure?',cfg.dur.maxRT);
end


function [tim, log] = StartExp(cfg, log)
%% StartExp
%--------------------

% initialize the timing
tim = [];

% present a start screen

% present instructions before the baseline session
if strcmpi(cfg.sessionName,'baseline')
  Instruction(cfg);
elseif cfg.flg.tms
  % or a few test pulses before the start of the expression session
  TestPulses(cfg);
end

% synchronize clock with screen, and get offset?
tim.start = GetSecs;
log.tim.offset = tim.start;

% save the logfile header
LogHeader(tim, log);

% TODO: probably a good idea to save the cfg and log as well


function [tim, key, previousPress, previousRelease] = WaitResponse(h,key,flgPressRelease,escapeTime,escapeKey,flgResetQueue)
%--------------------------------------------------------------------------
% WaitResponse: wait for the press or release of a specified key. Please
% create and start a cue before calling this function and stop and close
% the queue afterwards.
%
% KbQueueCreate(h_keyboard);
% KbQueueStart(h_keyboard);
% (do your magic here)
% KbQueueStop(h_keyboard);
% KbQueueRelease(h_keyboard);
%
%
% INPUT
% key           - any (set of) key(s) on the keyboard, for example: KbName('1!')
% flgPressRelease  - 1 to detect key press, 0 for release
% escapeTime   - always return after this (absolute time)
% escapeKey 	- always return if this key is pressed. For example: escapeKey = KbName('ESCAPE')
% h_keyboard    - deviceIndex of the keyboard
%
% OUTPUT
% tim           - time of event (press, release, or escape)
% key           - key number, or 0 for time, or -1 for escape key
%
% Copyright (C) 2013-2017, Lennart Verhagen
% lennart.verhagen@psy.ox.ac.uk
% version 2017-08-22
%--------------------------------------------------------------------------

% sort input and set defaults
if nargin < 6,	flgResetQueue = 1;              end % reset the queue
if nargin < 5,	escapeKey = 0;                  end % do not use an escapeKey
if nargin < 4,  escapeTime = GetSecs + 10;      end % 10 seconds
if nargin < 3,  flgPressRelease = 1;            end % look for presses
if nargin < 2,  key = 1:256;                    end % look for all keys
if nargin < 1,	h = [];                         end % default keyboard

% provide fall-back options
if isempty(key),        key = 1:256;                  end
if isempty(escapeKey),  escapeKey = 0;                end
if escapeKey < 0 || escapeKey > 256,	escapeKey = 0;	end

% The cue should not be created or flushed while keys are pressed. To clear
% the queue you can call KbQueueCheck once before checking. If you want to
% be responsive to key events that happened (just) before or during the
% call to this function, set flgResetQueue to 0. If you only want to
% be responsive from this time point on, set flgResetQueue to 1.
if flgResetQueue
  KbQueueCheck(h);
end

% start an infinite loop (that can be broken)
tim  = [];
previousPress = zeros(1,256);
previousRelease = zeros(1,256);
while true
  
  % check the queue for key presses
  [ ~, firstPress, firstRelease, lastPress, lastRelease] = KbQueueCheck(h);
  
  % break the while-loop if one of the criteria is reached
  if flgPressRelease && any(lastPress(key))
    % target key is pressed
    tim = lastPress(key);
    key = key(tim>0);
    tim = tim(tim>0);
  elseif ~flgPressRelease && any(lastRelease(key))
    % target key is released
    tim = lastRelease(key);
    key = key(tim>0);
    tim = tim(tim>0);
  elseif escapeKey>0 && lastPress(escapeKey)
    % escape key is pressed
    %tim = GetSecs;
    tim = lastPress(escapeKey);
    key = -1;
  elseif GetSecs >= escapeTime
    % time has run out
    tim = GetSecs;
    key = 0;
  end
  
  if ~isempty(tim)
    break
  elseif any(lastPress) || any(lastRelease)
    % store the last key press, but continue the loop (waiting for key)
    previousPress = previousPress + double(lastPress>0);
    previousRelease = previousPress + double(lastRelease>0);
  end
end

% ensure the key and tim are scalars
if isempty(key) || isempty(tim)
  % when the keyboard acts up, please log an error
  key = 0;
  tim = GetSecs;
end
if numel(key) > 1 || numel(key) > 1
  % when two (target) keys are pressed simultaneously, please log an error
  key = -sum(key);
  tim = mean(tim);
end


function LogHeader(tim, log)
%% LogHeader
%----------
% write header to file
fileID = fopen(log.fileName.header,'a');
if exist(log.fileName.header,'file')==2, fprintf(fileID,'\n\n'); end
fprintf(fileID,'----------------------------------------\n');
fprintf(fileID,'MYELIN and PLASTICITY\n');
fprintf(fileID,'\tpaired-associative Transcranial Magnetic Stimulation\n');
fprintf(fileID,'\tquantitative Magnetic Resonance Imaging\n');
fprintf(fileID,'\tflanker task, targeting right IFG and left M1\n');
fprintf(fileID,'\tAlberto Lazari, Olof van der Werf, and Lennart Verhagen\n\n');
fprintf(fileID,'date:\t\t%s\n',datestr(now));
fprintf(fileID,'subject:\t%s\n',log.subjectName);
fprintf(fileID,'session:\t%s\n',log.sessionName);
fprintf(fileID,'timeStart:\t%.6f\n\n',tim.start);
fprintf(fileID,'variables:\n');
fprintf(fileID,'\t%s\n',log.varName{:});
fprintf(fileID,'----------------------------------------\n');
fclose(fileID);


function [log] = LogSet(log, t, varName, dat)
%% LogSet
%----------
idx = ismember(log.varName,varName);
if ~any(idx), warning('paTMS:log:varNameUnknown','variable name ''%s'' not recognized',varName); end

% adjust timing if needed
if ~isempty(regexp(varName,log.tim.varIdentifier,'once')) == 1 && dat > 0
    dat = dat - log.tim.offset;
end

% store data in logfile matrix
log.data(t,idx) = dat;


function [dat] = LogGet(log, t, varName)
%% LogGet
%----------
idx = ismember(log.varName,varName);
if ~any(idx), warning('paTMS:log:varNameUnknown','variable name ''%s'' not recognized',varName); end

% retrieve data from logfile matrix
dat = log.data(t,idx);


function [log] = LogSetColumn(log,varName,dat)
%% LogSetColumn
%----------
log = LogSet(log, true(size(log.data,1),1), varName, dat);


function [dat] = LogGetColumn(log,varName)
%% LogSetColumn
%----------
dat = LogGet(log, true(size(log.data,1),1), varName);


function LogWrite(log, t)
%% LogWrite
%----------
% write the trial data to the logfile
%dlmwrite(log.fileName.data,log.data(t,:),'precision',6,'-append','delimiter','\t');

% exctract the trial data from the log
dat = log.data(t,:);

% create a format string that matches the logfile data type
formatStr = repmat({'%.6f\t'},1,length(log.varName));     % by default all data are fixed-point numbers
formatStr(rem(dat,1)==0) = {'%d\t'};                      % replace integers
formatStr = regexprep(strcat(formatStr{:}),'\\t$','\\n'); % concatenate and replace last tab by a new-line

% write the logfile to the disk
fileID = fopen(log.fileName.data,'a');
fprintf(fileID,formatStr,log.data(t,:));
fclose(fileID);


function CleanUp(h, pref)
%% CleanUp
%----------
if nargin < 1, h.keyboard = []; end
if nargin < 2, pref = []; end

% enable keyboard for Matlab
ListenChar(0);
% close and release cue
KbQueueStop(h.keyboard);
KbQueueRelease(h.keyboard);

% shutdown realtime scheduling
Priority(0);

% close window and restore cursor and other settings
sca;

% close all visible and hidden (serial) ports
IOPort('CloseAll');
if ~isempty(instrfindall), fclose(instrfindall); end

% TODO: how to close the parallel port?
h.port = [];

% restore preferences
if ~isempty(pref)
  if isfield(pref.old,'SyncTestSettings')
    Screen('Preference','SyncTestSettings',pref.old.SyncTestSettings{:});
  end
  if isfield(pref.old,'SkipSyncTests')
    Screen('Preference','SkipSyncTests',pref.old.SkipSyncTests);
    Screen('Preference','VisualDebugLevel',pref.old.VisualDebugLevel);
    Screen('Preference','SuppressAllWarnings',pref.old.SupressAllWarnings);
  end
end

% TODO: somehow after starting the KbQueue I can no longer use KbName

