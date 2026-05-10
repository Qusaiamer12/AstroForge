%% ========================================================================
%%  ASTROFORGE: AUTONOMOUS SPACE DEBRIS CAPTURE AND RECYCLING SYSTEM
%%  MASTER CONTROL SYSTEM V5.2
%%
%%  Team: Nova Foundary
%%  Lead Engineer: Qusai Amer (Mechatronics Engineering, The Hashemite University)
%%  Event: AESS Sustainability Hackathon 2026 - Track 4
%% ========================================================================

clear all; close all; clc;

fprintf('\n========================================================================\n');
fprintf(' ASTROFORGE DIGITAL TWIN - SYSTEM INITIALIZATION (V5.2)\n');
fprintf('========================================================================\n');
fprintf('[INFO] Loading Physical Parameters...\n');

%% ========================================================================
%%  SECTION 1: PHYSICAL PARAMETERS
%% ========================================================================

% --- SATELLITE PARAMETERS ---
satellite.mass = 795;                    % kg (Total Mass)
satellite.Ixx = 398.7;                   % kg.m^2 (Moment of Inertia - X)
satellite.Iyy = 508.1;                   % kg.m^2 (Moment of Inertia - Y)
satellite.Izz = 183.8;                   % kg.m^2 (Moment of Inertia - Z, Yaw)
satellite.dimensions = [0.2, 0.2, 0.34]; % m (Core dimensions)
satellite.drag_coeff = 2.2;              % Aerodynamic drag coefficient
satellite.surface_area = 0.8;            % m^2 (Frontal surface area)

fprintf('  -> Satellite Mass: %.0f kg\n', satellite.mass);
fprintf('  -> Moment of Inertia (Izz): %.1f kg.m^2\n', satellite.Izz);

% --- SOLAR POWER SYSTEM ---
power.solar_area = 2.62;                 % m^2 (Total panel area)
power.solar_efficiency = 0.28;           % 28% (Solar cell efficiency)
power.solar_constant = 1361;             % W/m^2 (Solar constant in LEO/SSO)
power.solar_output = 1000;               % W (Calculated effective output)

fprintf('  -> Solar Power Output: %.0f W\n', power.solar_output);

% --- BATTERY SYSTEM (Lithium-ion) ---
battery.capacity_Wh = 5000;              % 5 kWh (System capacity)
battery.capacity_J = battery.capacity_Wh * 3600; % 18,000,000 J
battery.voltage = 28;                    % V (Nominal voltage)
battery.max_current = 50;                % A (Max safe discharge current)
battery.DOD_safe = 0.2;                  % 20% (Safe Depth of Discharge)
battery.initial_SOC = battery.capacity_J; % 100% Initial state of charge

fprintf('  -> Battery Capacity: %.1f kWh (%.1f MJ)\n', battery.capacity_Wh/1000, battery.capacity_J/1e6);

% --- SUPERCAPACITOR (Braking System) ---
supercap.capacity_F = 500;               % Farads
supercap.voltage_max = 28;               % V (Max voltage)
supercap.energy_max = 0.5 * supercap.capacity_F * (supercap.voltage_max^2); % 196,000 J
supercap.initial_energy = 20000;         % 20 kJ (Initial charge)
supercap.charge_current = 3.6;           % A (Slow charge current)
supercap.discharge_current = 20;         % A (Fast discharge for braking)
supercap.charge_power = supercap.voltage_max * supercap.charge_current; % 100.8 W

fprintf('  -> SuperCap Energy: %.0f kJ (%.0f%% charged)\n', supercap.initial_energy/1000, (supercap.initial_energy/supercap.energy_max)*100);

% --- SPACE DEBRIS PARAMETERS ---
debris.mass = 15;                        % kg (Fragment mass)
debris.initial_velocity = 50;            % m/s (Relative velocity at capture)
debris.initial_distance = 10;            % m (Initial detection distance)
debris.cross_section = 0.05;             % m^2 (Cross-sectional area)
debris.material = 'Aluminum';            % Target material
debris.conductivity = 3.5e7;             % S/m (Electrical conductivity)
debris.thickness = 0.002;                % m (2 mm wall thickness)
debris.kinetic_energy = 0.5 * debris.mass * (debris.initial_velocity^2); % 18,750 J

fprintf('  -> Target Debris: %.0f kg @ %.0f m/s (KE = %.1f kJ)\n', debris.mass, debris.initial_velocity, debris.kinetic_energy/1000);

% --- EDDY CURRENT BRAKE ---
brake.coil_turns = 715;                  % Calculated turns
brake.coil_radius = 0.2;                 % m (Coil radius)
brake.coil_length = 0.5;                 % m (Solenoid length)
brake.wire_diameter = 0.001;             % m (1 mm copper wire)
brake.wire_resistivity = 1.68e-8;        % Ohm.m (Copper resistivity at 20C)
brake.operating_current = 20;            % A (Operating current)
brake.operating_voltage = 28;            % V (From SuperCap)
brake.operating_power = brake.operating_voltage * brake.operating_current; % 560 W
brake.mu0 = 4*pi*1e-7;                   % H/m (Magnetic permeability)

% Coil Electrical Resistance Calculation
brake.wire_length = brake.coil_turns * 2 * pi * brake.coil_radius; 
brake.wire_area = pi * (brake.wire_diameter/2)^2;                  
brake.resistance = (brake.wire_resistivity * brake.wire_length) / brake.wire_area; 

fprintf('  -> Brake Coil: %d turns, %.2f Ohms, %.0f W\n', brake.coil_turns, brake.resistance, brake.operating_power);

% --- IRIS CAPTURE MECHANISM ---
iris.num_blades = 6;                     % Hexagonal design
iris.max_angle = 90;                     % deg (Fully open)
iris.min_angle = 0;                      % deg (Fully closed)
iris.opening_speed = 45;                 % deg/s (Actuation speed)
iris.motor_power = 50;                   % W (Per servo motor)
iris.total_motor_power = iris.num_blades * iris.motor_power; % 300 W

fprintf('  -> Iris Mechanism: %d blades, %.0f W total\n', iris.num_blades, iris.total_motor_power);

% --- ELECTRICAL LOADS ---
loads.standby = 180;                     % W (OBC + Sensors + Comms)
loads.camera = 20;                       % W (Optical tracking)
loads.motors_attitude = 100;             % W (Reaction Wheels)
loads.motors_iris = iris.total_motor_power; % 300 W (Iris motors)
loads.braking = brake.operating_power;   % 560 W (Eddy Current Brake)

fprintf('  -> Total Peak Load: %.0f W\n', loads.standby + loads.camera + loads.motors_attitude + loads.motors_iris + loads.braking);

% --- PID CONTROLLER GAINS ---
% ADCS (Attitude Determination & Control System)
ADCS.Kp = 200;                           % Proportional
ADCS.Ki = 2;                             % Integral
ADCS.Kd = 350;                           % Derivative
ADCS.max_torque = 0.5;                   % N.m (Max reaction wheel torque)
ADCS.natural_freq = sqrt(ADCS.Kp / satellite.Izz); 
ADCS.damping_ratio = ADCS.Kd / (2 * sqrt(ADCS.Kp * satellite.Izz)); 

fprintf('  -> ADCS PID: Kp=%.0f, Ki=%.0f, Kd=%.0f (Zeta=%.2f)\n', ADCS.Kp, ADCS.Ki, ADCS.Kd, ADCS.damping_ratio);

% IRIS Position Control
IRIS.Kp = 50;                            
IRIS.Ki = 5;                             
IRIS.Kd = 20;                            

% --- MISSION TIMELINE ---
mission.t_debris_detect = 5;            % s (Radar detection)
mission.t_iris_open = 7;                % s (Iris actuation)
mission.t_debris_capture = 10;          % s (Debris enters chamber + Braking initiates)
mission.t_iris_close = 12;              % s (Iris closure)
mission.t_braking_duration = 8;         % s (Estimated braking duration)
mission.t_total = 80;                   % s (Total simulation time)

% --- SIMULATION PARAMETERS ---
sim.sample_time = 0.01;                 % s (10 ms step)
sim.solver = 'ode3';                    % Bogacki-Shampine solver

fprintf('  -> Mission Duration: %.0f seconds\n', mission.t_total);
fprintf('  -> Sample Time: %.0f ms\n', sim.sample_time * 1000);

%% ========================================================================
%%  SECTION 2: WORKSPACE EXPORT
%% ========================================================================

fprintf('[INFO] Saving parameters to workspace...\n');

assignin('base', 'satellite', satellite);
assignin('base', 'power', power);
assignin('base', 'battery', battery);
assignin('base', 'supercap', supercap);
assignin('base', 'debris', debris);
assignin('base', 'brake', brake);
assignin('base', 'iris', iris);
assignin('base', 'loads', loads);
assignin('base', 'ADCS', ADCS);
assignin('base', 'IRIS', IRIS);
assignin('base', 'mission', mission);
assignin('base', 'sim', sim);

%% ========================================================================
%%  SECTION 3: BUILD SIMULINK MODEL
%% ========================================================================

fprintf('[INFO] Building Simulink Model...\n');

modelName = 'AstroForge_Ultimate_V5_2';

if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
if exist([modelName '.slx'], 'file')
    delete([modelName '.slx']);
end

new_system(modelName);
open_system(modelName);

set_param(modelName, 'StopTime', num2str(mission.t_total));
set_param(modelName, 'SolverType', 'Fixed-step');
set_param(modelName, 'Solver', sim.solver);
set_param(modelName, 'FixedStep', num2str(sim.sample_time));
set_param(modelName, 'SaveOutput', 'on', 'OutputSaveName', 'yout');
set_param(modelName, 'SaveFinalState', 'on', 'FinalStateName', 'xFinal');

fprintf('  -> Model created: %s | Solver: %s\n', modelName, sim.solver);

%% --- SUBSYSTEM 1: MISSION COMMANDER ---
add_block('simulink/Sources/Step', [modelName '/Debris_Detected']);
set_param([modelName '/Debris_Detected'], 'Time', num2str(mission.t_debris_detect), 'After', '1', 'Position', [50, 50, 120, 80]);

add_block('simulink/Sources/Step', [modelName '/Debris_Inside']);
set_param([modelName '/Debris_Inside'], 'Time', num2str(mission.t_debris_capture), 'After', '1', 'Position', [50, 120, 120, 150]);

add_block('simulink/User-Defined Functions/MATLAB Function', [modelName '/Mission_Commander']);
set_param([modelName '/Mission_Commander'], 'Position', [220, 40, 500, 300]);

commanderCode = sprintf([...
'function [Yaw_Cmd, Iris_Cmd, Battery_Load, Cap_Charge, Cap_Discharge, Mission_Phase] = fcn(Debris_Seen, Debris_In, Battery_SOC, Cap_SOC)\n', ...
'%%#codegen\n', ...
'Standby_Load = 180;\n', ...
'Camera_Load = 20;\n', ...
'Attitude_Motors = 100;\n', ...
'Iris_Motors = 300;\n', ...
'Cap_Charge_Power = 100;\n', ...
'Brake_Power = 560;\n', ...
'\n', ...
'Yaw_Cmd = 0;\n', ...
'Iris_Cmd = 0;\n', ...
'Battery_Load = Standby_Load;\n', ...
'Cap_Charge = 0;\n', ...
'Cap_Discharge = 0;\n', ...
'Mission_Phase = 0;\n', ...
'\n', ...
'if Debris_Seen == 0\n', ...
'    Mission_Phase = 0;\n', ...
'    Battery_Load = Standby_Load;\n', ...
'    if Cap_SOC < 180000\n', ...
'        Cap_Charge = Cap_Charge_Power;\n', ...
'        Battery_Load = Battery_Load + Cap_Charge_Power;\n', ...
'    end\n', ...
'elseif Debris_Seen == 1 && Debris_In == 0\n', ...
'    Mission_Phase = 1;\n', ...
'    Yaw_Cmd = 45;\n', ...
'    Iris_Cmd = 90;\n', ...
'    Battery_Load = Standby_Load + Camera_Load + Attitude_Motors + Iris_Motors;\n', ...
'    Cap_Charge = 0;\n', ...
'elseif Debris_In == 1\n', ...
'    Mission_Phase = 2;\n', ...
'    Yaw_Cmd = 0;\n', ...
'    Iris_Cmd = 0;\n', ...
'    if Cap_SOC > 1000\n', ...
'        Cap_Discharge = Brake_Power;\n', ...
'        Battery_Load = Standby_Load;\n', ...
'    else\n', ...
'        Cap_Discharge = 0;\n', ...
'        Battery_Load = Standby_Load + Brake_Power;\n', ...
'    end\n', ...
'end\n', ...
'\n', ...
'Battery_Critical = 3600000;\n', ...
'if Battery_SOC < Battery_Critical\n', ...
'    Battery_Load = Standby_Load;\n', ...
'    Cap_Charge = 0;\n', ...
'    Iris_Cmd = 0;\n', ...
'    Yaw_Cmd = 0;\n', ...
'end\n', ...
'\n', ...
'if Cap_SOC > 190000\n', ...
'    Cap_Charge = 0;\n', ...
'end\n']);

config_cmd = get_param([modelName '/Mission_Commander'], 'MATLABFunctionConfiguration');
config_cmd.FunctionScript = commanderCode;

%% --- SUBSYSTEM 2: DEBRIS DYNAMICS ---
add_block('simulink/User-Defined Functions/MATLAB Function', [modelName '/Brake_Force_Calculator']);
set_param([modelName '/Brake_Force_Calculator'], 'Position', [220, 370, 450, 490]);

brakeForceCode = sprintf([...
'function [F_brake, Accel] = fcn(Brake_Current, Velocity)\n', ...
'%%#codegen\n', ...
'mu0 = 4*pi*1e-7;\n', ...
'N = 715;\n', ...
'L_coil = 0.5;\n', ...
'sigma_Al = 3.5e7;\n', ...
'thickness = 0.002;\n', ...
'A_debris = 0.05;\n', ...
'debris_mass = 15;\n', ...
'\n', ...
'B = (mu0 * N * Brake_Current) / L_coil;\n', ...
'\n', ...
'if Velocity > 0.01\n', ...
'    F_brake = (B^2 * A_debris * Velocity * sigma_Al) / thickness;\n', ...
'else\n', ...
'    F_brake = 0;\n', ...
'end\n', ...
'\n', ...
'Accel = -F_brake / debris_mass;\n']);

config_brake = get_param([modelName '/Brake_Force_Calculator'], 'MATLABFunctionConfiguration');
config_brake.FunctionScript = brakeForceCode;

add_block('simulink/Discrete/Discrete-Time Integrator', [modelName '/Velocity_Integrator']);
set_param([modelName '/Velocity_Integrator'], 'InitialCondition', num2str(debris.initial_velocity), 'SampleTime', num2str(sim.sample_time), 'Position', [510, 390, 570, 430]);

add_block('simulink/Discontinuities/Saturation', [modelName '/Velocity_Limiter']);
set_param([modelName '/Velocity_Limiter'], 'UpperLimit', '100', 'LowerLimit', '0', 'Position', [610, 395, 650, 425]);

add_block('simulink/Discrete/Discrete-Time Integrator', [modelName '/Distance_Integrator']);
set_param([modelName '/Distance_Integrator'], 'InitialCondition', num2str(debris.initial_distance), 'SampleTime', num2str(sim.sample_time), 'Position', [690, 390, 750, 430]);

add_block('simulink/User-Defined Functions/MATLAB Function', [modelName '/Debris_Status']);
set_param([modelName '/Debris_Status'], 'Position', [790, 370, 960, 490]);

debrisStatusCode = sprintf([...
'function [KE, Stopped] = fcn(Velocity)\n', ...
'%%#codegen\n', ...
'debris_mass = 15;\n', ...
'KE = 0.5 * debris_mass * Velocity^2;\n', ...
'if Velocity < 0.01\n', ...
'    Stopped = 1;\n', ...
'else\n', ...
'    Stopped = 0;\n', ...
'end\n']);

config_status = get_param([modelName '/Debris_Status'], 'MATLABFunctionConfiguration');
config_status.FunctionScript = debrisStatusCode;

add_line(modelName, 'Brake_Force_Calculator/2', 'Velocity_Integrator/1', 'autorouting', 'on');
add_line(modelName, 'Velocity_Integrator/1', 'Velocity_Limiter/1', 'autorouting', 'on');
add_line(modelName, 'Velocity_Limiter/1', 'Distance_Integrator/1', 'autorouting', 'on');
add_line(modelName, 'Velocity_Limiter/1', 'Debris_Status/1', 'autorouting', 'on');
add_line(modelName, 'Velocity_Limiter/1', 'Brake_Force_Calculator/2', 'autorouting', 'on');

%% --- SUBSYSTEM 3: POWER MANAGEMENT ---
add_block('simulink/Sources/Constant', [modelName '/Solar_Panels']);
set_param([modelName '/Solar_Panels'], 'Value', num2str(power.solar_output), 'Position', [50, 580, 120, 610]);

add_block('simulink/Math Operations/Subtract', [modelName '/Battery_Net_Power']);
set_param([modelName '/Battery_Net_Power'], 'Position', [500, 575, 540, 625]);

add_block('simulink/Discrete/Discrete-Time Integrator', [modelName '/Battery_SOC']);
set_param([modelName '/Battery_SOC'], 'InitialCondition', num2str(battery.initial_SOC), 'SampleTime', num2str(sim.sample_time), 'Position', [590, 580, 650, 620]);

add_block('simulink/Math Operations/Subtract', [modelName '/SuperCap_Net_Power']);
set_param([modelName '/SuperCap_Net_Power'], 'Position', [500, 685, 540, 735]);

add_block('simulink/Discrete/Discrete-Time Integrator', [modelName '/SuperCap_SOC']);
set_param([modelName '/SuperCap_SOC'], 'InitialCondition', num2str(supercap.initial_energy), 'SampleTime', num2str(sim.sample_time), 'Position', [590, 690, 650, 730]);

add_line(modelName, 'Solar_Panels/1', 'Battery_Net_Power/1', 'autorouting', 'on');
add_line(modelName, 'Mission_Commander/3', 'Battery_Net_Power/2', 'autorouting', 'on');
add_line(modelName, 'Battery_Net_Power/1', 'Battery_SOC/1', 'autorouting', 'on');
add_line(modelName, 'Mission_Commander/4', 'SuperCap_Net_Power/1', 'autorouting', 'on');
add_line(modelName, 'Mission_Commander/5', 'SuperCap_Net_Power/2', 'autorouting', 'on');
add_line(modelName, 'SuperCap_Net_Power/1', 'SuperCap_SOC/1', 'autorouting', 'on');
add_line(modelName, 'Battery_SOC/1', 'Mission_Commander/3', 'autorouting', 'on');
add_line(modelName, 'SuperCap_SOC/1', 'Mission_Commander/4', 'autorouting', 'on');

%% --- SUBSYSTEM 4: THERMAL MANAGEMENT ---
add_block('simulink/User-Defined Functions/MATLAB Function', [modelName '/Coil_Temperature']);
set_param([modelName '/Coil_Temperature'], 'Position', [220, 810, 480, 950]);

thermalCode = sprintf([...
'function [Temp, Overheated] = fcn(Brake_Current, prev_temp)\n', ...
'%%#codegen\n', ...
'rho_copper = 1.68e-8;\n', ...
'wire_diameter = 0.001;\n', ...
'N = 715;\n', ...
'coil_radius = 0.2;\n', ...
'wire_length = N * 2 * pi * coil_radius;\n', ...
'wire_area = pi * (wire_diameter/2)^2;\n', ...
'R_coil = (rho_copper * wire_length) / wire_area;\n', ...
'P_heat = Brake_Current^2 * R_coil;\n', ...
'\n', ...
'C_thermal = 500;\n', ...
'R_thermal = 0.1;\n', ...
'T_space = -150;\n', ...
'dt = 0.01;\n', ...
'dT = (P_heat - (prev_temp - T_space)/R_thermal) / C_thermal;\n', ...
'temp = prev_temp + dT * dt;\n', ...
'\n', ...
'T_max = 150;\n', ...
'if temp > T_max\n', ...
'    Overheated = 1;\n', ...
'else\n', ...
'    Overheated = 0;\n', ...
'end\n', ...
'Temp = temp;\n']);

config_thermal = get_param([modelName '/Coil_Temperature'], 'MATLABFunctionConfiguration');
config_thermal.FunctionScript = thermalCode;

add_block('simulink/Discrete/Unit Delay', [modelName '/Temp_Memory']);
set_param([modelName '/Temp_Memory'], 'InitialCondition', '-150', 'SampleTime', num2str(sim.sample_time), 'Position', [540, 855, 580, 885]);

add_line(modelName, 'Coil_Temperature/1', 'Temp_Memory/1', 'autorouting', 'on');
add_line(modelName, 'Temp_Memory/1', 'Coil_Temperature/2', 'autorouting', 'on');

%% --- SUBSYSTEM 5: ATTITUDE CONTROL (ADCS) ---
add_block('simulink/Sources/Constant', [modelName '/Desired_Attitude']);
set_param([modelName '/Desired_Attitude'], 'Value', '0', 'Position', [50, 1000, 120, 1030]);

add_block('simulink/Math Operations/Subtract', [modelName '/Attitude_Error']);
set_param([modelName '/Attitude_Error'], 'Position', [560, 995, 600, 1045]);

add_block('simulink/Continuous/PID Controller', [modelName '/PID_ADCS']);
set_param([modelName '/PID_ADCS'], 'P', 'ADCS.Kp', 'I', 'ADCS.Ki', 'D', 'ADCS.Kd', 'Position', [640, 990, 740, 1050]);

add_block('simulink/Discontinuities/Saturation', [modelName '/Torque_Limit']);
set_param([modelName '/Torque_Limit'], 'UpperLimit', 'ADCS.max_torque', 'LowerLimit', '-ADCS.max_torque', 'Position', [780, 995, 820, 1045]);

add_block('simulink/Continuous/Transfer Fcn', [modelName '/Satellite_Dynamics']);
set_param([modelName '/Satellite_Dynamics'], 'Numerator', '[1]', 'Denominator', '[satellite.Izz 0 0]', 'Position', [860, 995, 970, 1045]);

add_line(modelName, 'Mission_Commander/1', 'Attitude_Error/1', 'autorouting', 'on');
add_line(modelName, 'Desired_Attitude/1', 'Attitude_Error/2', 'autorouting', 'on');
add_line(modelName, 'Attitude_Error/1', 'PID_ADCS/1', 'autorouting', 'on');
add_line(modelName, 'PID_ADCS/1', 'Torque_Limit/1', 'autorouting', 'on');
add_line(modelName, 'Torque_Limit/1', 'Satellite_Dynamics/1', 'autorouting', 'on');

%% --- SUBSYSTEM 6: IRIS MECHANISM CONTROL ---
add_block('simulink/Math Operations/Subtract', [modelName '/Iris_Error']);
set_param([modelName '/Iris_Error'], 'Position', [560, 1125, 600, 1175]);

add_block('simulink/Continuous/PID Controller', [modelName '/PID_Iris']);
set_param([modelName '/PID_Iris'], 'P', 'IRIS.Kp', 'I', 'IRIS.Ki', 'D', 'IRIS.Kd', 'Position', [640, 1120, 740, 1180]);

add_block('simulink/Continuous/Transfer Fcn', [modelName '/Servo_Motor']);
set_param([modelName '/Servo_Motor'], 'Numerator', '[iris.opening_speed]', 'Denominator', '[1 1]', 'Position', [780, 1125, 890, 1175]);

add_block('simulink/Discontinuities/Saturation', [modelName '/Iris_Angle_Limit']);
set_param([modelName '/Iris_Angle_Limit'], 'UpperLimit', num2str(iris.max_angle), 'LowerLimit', num2str(iris.min_angle), 'Position', [930, 1130, 970, 1170]);

add_line(modelName, 'Mission_Commander/2', 'Iris_Error/1', 'autorouting', 'on');
add_line(modelName, 'Iris_Angle_Limit/1', 'Iris_Error/2', 'autorouting', 'on');
add_line(modelName, 'Iris_Error/1', 'PID_Iris/1', 'autorouting', 'on');
add_line(modelName, 'PID_Iris/1', 'Servo_Motor/1', 'autorouting', 'on');
add_line(modelName, 'Servo_Motor/1', 'Iris_Angle_Limit/1', 'autorouting', 'on');

%% --- SUBSYSTEM 7: TELEMETRY & DASHBOARD ---
add_block('built-in/Subsystem', [modelName '/Telemetry_Dashboard']);
set_param([modelName '/Telemetry_Dashboard'], 'Position', [1100, 400, 1350, 750]);

indicators = {
    'Battery_Percent', 'Battery SOC (%)';
    'SuperCap_Percent', 'SuperCap SOC (%)';
    'Debris_Velocity', 'Debris Vel (m/s)';
    'Coil_Temperature', 'Coil Temp (C)';
    'Mission_Phase', 'Mission Phase';
    'Brake_Power', 'Brake Power (W)';
    'Iris_Angle', 'Iris Angle (deg)';
    'Satellite_Angle', 'Sat Angle (deg)';
    'Debris_KE', 'Debris KE (kJ)';
    'Overheat_Warning', 'Overheat';
    'Debris_Stopped', 'Debris Stopped'
};

yPos = 50;
for i = 1:size(indicators, 1)
    inportName = [modelName '/Telemetry_Dashboard/In' num2str(i)];
    add_block('simulink/Sources/In1', inportName);
    set_param(inportName, 'Position', [30, yPos, 60, yPos+20]);
    
    dispName = [modelName '/Telemetry_Dashboard/' indicators{i,1}];
    add_block('simulink/Sinks/Display', dispName);
    set_param(dispName, 'Decimation', '10', 'Format', 'short', 'Position', [150, yPos-5, 280, yPos+25]);
    
    add_line([modelName '/Telemetry_Dashboard'], ['In' num2str(i) '/1'], [indicators{i,1} '/1'], 'autorouting', 'on');
    yPos = yPos + 60;
end

add_block('simulink/Math Operations/Gain', [modelName '/Battery_to_Percent']);
set_param([modelName '/Battery_to_Percent'], 'Gain', '100/18000000', 'Position', [720, 560, 750, 590]);
add_line(modelName, 'Battery_SOC/1', 'Battery_to_Percent/1', 'autorouting', 'on');
add_line(modelName, 'Battery_to_Percent/1', 'Telemetry_Dashboard/1', 'autorouting', 'on');

add_block('simulink/Math Operations/Gain', [modelName '/Cap_to_Percent']);
set_param([modelName '/Cap_to_Percent'], 'Gain', '100/20000', 'Position', [720, 670, 750, 700]);
add_line(modelName, 'SuperCap_SOC/1', 'Cap_to_Percent/1', 'autorouting', 'on');
add_line(modelName, 'Cap_to_Percent/1', 'Telemetry_Dashboard/2', 'autorouting', 'on');

add_line(modelName, 'Velocity_Limiter/1', 'Telemetry_Dashboard/3', 'autorouting', 'on');
add_line(modelName, 'Coil_Temperature/1', 'Telemetry_Dashboard/4', 'autorouting', 'on');
add_line(modelName, 'Mission_Commander/6', 'Telemetry_Dashboard/5', 'autorouting', 'on');
add_line(modelName, 'Mission_Commander/5', 'Telemetry_Dashboard/6', 'autorouting', 'on');
add_line(modelName, 'Iris_Angle_Limit/1', 'Telemetry_Dashboard/7', 'autorouting', 'on');
add_line(modelName, 'Satellite_Dynamics/1', 'Telemetry_Dashboard/8', 'autorouting', 'on');

add_block('simulink/Math Operations/Gain', [modelName '/KE_to_kJ']);
set_param([modelName '/KE_to_kJ'], 'Gain', '0.001', 'Position', [1000, 410, 1030, 440]);
add_line(modelName, 'Debris_Status/1', 'KE_to_kJ/1', 'autorouting', 'on');
add_line(modelName, 'KE_to_kJ/1', 'Telemetry_Dashboard/9', 'autorouting', 'on');

add_line(modelName, 'Coil_Temperature/2', 'Telemetry_Dashboard/10', 'autorouting', 'on');
add_line(modelName, 'Debris_Status/2', 'Telemetry_Dashboard/11', 'autorouting', 'on');

%% --- SUBSYSTEM 8: VISUALIZATION SCOPES ---
add_block('simulink/Sinks/Scope', [modelName '/Power_Management']);
set_param([modelName '/Power_Management'], 'NumInputPorts', '2', 'Position', [720, 575, 800, 725]);
add_line(modelName, 'Battery_SOC/1', 'Power_Management/1', 'autorouting', 'on');
add_line(modelName, 'SuperCap_SOC/1', 'Power_Management/2', 'autorouting', 'on');

add_block('simulink/Sinks/Scope', [modelName '/Debris_Dynamics']);
set_param([modelName '/Debris_Dynamics'], 'NumInputPorts', '3', 'Position', [1000, 370, 1080, 490]);
add_line(modelName, 'Velocity_Limiter/1', 'Debris_Dynamics/1', 'autorouting', 'on');
add_line(modelName, 'Distance_Integrator/1', 'Debris_Dynamics/2', 'autorouting', 'on');
add_line(modelName, 'Debris_Status/1', 'Debris_Dynamics/3', 'autorouting', 'on');

add_block('simulink/Sinks/Scope', [modelName '/Thermal_Management']);
set_param([modelName '/Thermal_Management'], 'NumInputPorts', '2', 'Position', [620, 810, 700, 950]);
add_line(modelName, 'Coil_Temperature/1', 'Thermal_Management/1', 'autorouting', 'on');
add_line(modelName, 'Coil_Temperature/2', 'Thermal_Management/2', 'autorouting', 'on');

add_block('simulink/Sinks/Scope', [modelName '/ADCS_Iris_Control']);
set_param([modelName '/ADCS_Iris_Control'], 'NumInputPorts', '4', 'Position', [1010, 995, 1090, 1175]);
add_line(modelName, 'Mission_Commander/1', 'ADCS_Iris_Control/1', 'autorouting', 'on');
add_line(modelName, 'Satellite_Dynamics/1', 'ADCS_Iris_Control/2', 'autorouting', 'on');
add_line(modelName, 'Mission_Commander/2', 'ADCS_Iris_Control/3', 'autorouting', 'on');
add_line(modelName, 'Iris_Angle_Limit/1', 'ADCS_Iris_Control/4', 'autorouting', 'on');

%% --- SUBSYSTEM 9: AUTO-STOP ---
add_block('simulink/Sinks/Stop Simulation', [modelName '/Auto_Stop']);
set_param([modelName '/Auto_Stop'], 'Position', [1000, 520, 1080, 550]);
add_line(modelName, 'Debris_Status/2', 'Auto_Stop/1', 'autorouting', 'on');

%% --- SECTION 4: FINAL CONNECTIONS ---
add_line(modelName, 'Debris_Detected/1', 'Mission_Commander/1', 'autorouting', 'on');
add_line(modelName, 'Debris_Inside/1', 'Mission_Commander/2', 'autorouting', 'on');
add_line(modelName, 'Mission_Commander/5', 'Brake_Force_Calculator/1', 'autorouting', 'on');
add_line(modelName, 'Mission_Commander/5', 'Coil_Temperature/1', 'autorouting', 'on');

%% --- SECTION 5: ARRANGE, SAVE & DATA LOGGING ---
try Simulink.BlockDiagram.arrangeSystem(modelName); catch, end

set_param([modelName '/Velocity_Limiter'], 'DataLogging', 'on', 'DataLoggingName', 'Debris_Velocity');
set_param([modelName '/Battery_SOC'], 'DataLogging', 'on', 'DataLoggingName', 'Battery_Energy');
set_param([modelName '/SuperCap_SOC'], 'DataLogging', 'on', 'DataLoggingName', 'SuperCap_Energy');
set_param([modelName '/Coil_Temperature'], 'DataLogging', 'on', 'DataLoggingName', 'Coil_Temp');
set_param([modelName '/Satellite_Dynamics'], 'DataLogging', 'on', 'DataLoggingName', 'Satellite_Angle');

save_system(modelName);
fprintf('[INFO] Model configured and saved successfully.\n');

%% ========================================================================
%%  POST-SIMULATION ANALYSIS FUNCTION
%% ========================================================================
function plot_results()
    fprintf('[INFO] Generating analysis plots...\n');
    try
        debris_vel = evalin('base', 'Debris_Velocity.Data');
        time = evalin('base', 'Debris_Velocity.Time');
        battery = evalin('base', 'Battery_Energy.Data');
        supercap = evalin('base', 'SuperCap_Energy.Data');
        temp = evalin('base', 'Coil_Temp.Data');
        
        fig = figure('Name', 'AstroForge Mission Analysis', 'Position', [50, 50, 1600, 900], 'Color', 'white');
        
        subplot(2,3,1); plot(time, debris_vel, 'LineWidth', 2.5, 'Color', [0.85 0.2 0.2]); grid on;
        xlabel('Time (s)', 'FontWeight', 'bold'); ylabel('Velocity (m/s)', 'FontWeight', 'bold'); title('Debris Braking Performance'); ylim([0 55]);
        
        subplot(2,3,2); plot(time, battery/1e6, 'LineWidth', 2.5, 'Color', [0.2 0.6 0.2]); grid on;
        xlabel('Time (s)', 'FontWeight', 'bold'); ylabel('Energy (MJ)', 'FontWeight', 'bold'); title('Battery State of Charge');
        
        subplot(2,3,3); plot(time, supercap/1000, 'LineWidth', 2.5, 'Color', [0.2 0.2 0.8]); grid on;
        xlabel('Time (s)', 'FontWeight', 'bold'); ylabel('Energy (kJ)', 'FontWeight', 'bold'); title('SuperCapacitor Discharge');
        
        subplot(2,3,4); plot(time, temp, 'LineWidth', 2.5, 'Color', [0.9 0.5 0.1]); hold on;
        yline(150, '--r', 'Max Safe Temp', 'LineWidth', 2); grid on;
        xlabel('Time (s)', 'FontWeight', 'bold'); ylabel('Temperature (C)', 'FontWeight', 'bold'); title('Coil Thermal Profile');
        
        subplot(2,3,5); power_flow = [0; diff(battery)*100]; 
        plot(time, power_flow, 'LineWidth', 2, 'Color', [0.5 0.2 0.7]); grid on;
        xlabel('Time (s)', 'FontWeight', 'bold'); ylabel('Power (W)', 'FontWeight', 'bold'); title('Net Power Flow');
        
        subplot(2,3,6); axis off;
        stop_idx = find(debris_vel < 0.1, 1);
        if ~isempty(stop_idx), stop_time = time(stop_idx); else, stop_time = NaN; end
        
        energy_used = (supercap(1) - min(supercap))/1000;
        peak_temp = max(temp);
        battery_remaining = (battery(end)/18e6)*100;
        efficiency = (18750/(energy_used*1000))*100;
        
        summary = sprintf([...
            '----------------------------------------\n', ...
            ' MISSION SUMMARY REPORT \n', ...
            '----------------------------------------\n', ...
            ' Debris stopped in: %.2f s \n', ...
            ' Energy consumed: %.2f kJ \n', ...
            ' Peak temperature: %.1f C \n', ...
            ' Battery remaining: %.1f%% \n', ...
            ' Braking efficiency: %.1f%% \n', ...
            '----------------------------------------\n', ...
            ' STATUS: SUCCESS \n', ...
            '----------------------------------------'], ...
            stop_time, energy_used, peak_temp, battery_remaining, efficiency);
        
        text(0.05, 0.5, summary, 'FontSize', 11, 'FontName', 'Courier New', 'FontWeight', 'bold', 'VerticalAlignment', 'middle');
        
        saveas(fig, 'AstroForge_Mission_Results.png');
        
        T = table(time, debris_vel, battery, supercap, temp, 'VariableNames', {'Time_s', 'Debris_Velocity_ms', 'Battery_J', 'SuperCap_J', 'Coil_Temp_C'});
        writetable(T, 'AstroForge_Mission_Data.xlsx');
        
    catch ME
        warning('Could not generate plots. Run simulation first.');
    end
end
assignin('base', 'plot_results', @plot_results);

fprintf('\n========================================================================\n');
fprintf(' BUILD COMPLETE - ASTROFORGE V5.2\n');
fprintf('========================================================================\n');
fprintf('To run the simulation: sim(''%s'')\n', modelName);
fprintf('To view the results:   plot_results()\n');
fprintf('========================================================================\n');
