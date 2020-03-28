function [turbine] = createTurbineModel(orig, hub_height, scale)

%% This function alters an original turbine model by a scaler amount.
% 
% Inputs: hub_height = the height of the turbine in meters
%         blade_length = the diameter of the turbines' blades
% 
% Outputs: model = the turbine model altered with the new values
% 
% Authors: William Valentine & Aaron Corcoran
turbine = load('turbineModel_v3.mat');

origVR = turbine.obj.vR_trans;
foo = turbine.obj.vR_trans;

hub_height_idx = find(foo(:,3) < -90);

foo(hub_height_idx,3) = -hub_height;

doo = rnorm(foo(:,2:3));

blade_length_idx = find(doo > 40 & doo < 47);

% figure; 
% plot(foo(blade_length_idx,2),foo(blade_length_idx,3),'.')
% axis equal
% 
% figure;
% plot(foo(blade_length_idx,2).*scale,foo(blade_length_idx,3).*scale,'.')
% axis equal

% foo(blade_length_idx,2) = blade_length;
% foo(blade_length_idx,3) = blade_length;
foo(blade_length_idx,2:3) = foo(blade_length_idx,2:3).*scale;

% figure; 
if orig
    plot3(origVR(:,1),origVR(:,2),origVR(:,3), '-');
else
    plot3(foo(:,1),foo(:,2),foo(:,3), '-');
end

% plot settings
axis equal;
grid on;
view(3);

%turbine.obj.vR_trans = foo;
% axis equal
end