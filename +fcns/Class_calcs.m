
%[B,dev,stats] = mnrfit([log_area(idx) track_speed(idx)],vert(idx))

sinuos = sinuosity(idx);
tbl = table(log_area, track_spd, sinuos, bat_bird);
model_spec = 'bat_bird ~ log_area + track_spd + sinuos';
%model_spec = 'vert ~ sinuos + track_spd';
[B,dev,stats] = mnrfit([log_area, track_spd, sinuos],3-cls,'model','hierarchical');
p1 = exp(B(1) + B(2)*log_area + B(3)*track_spd + B(4)*sinuos);
p2 = exp(B(5) + B(6)*log_area + B(7)*track_spd + B(8)*sinuos);
p3 = zeros(size(p1));
p3(p1>0.5) = 1;
p3(p2>0.5 & p1 > 0.5) = 2;
mdl  = fitglm(tbl,model_spec,'Distribution','binomial')
coefs = mdl.Coefficients.Estimate;
x = 1.8:0.1:6;
%x = 0:0.1:1;
y = (log(0.5) - coefs(1) - coefs(2)*x )/ coefs(3);
%figure; gscatter(log(track_area),track_speed,auto_class,'rgb','os*',4)
figure; gscatter(sinuosity,track_speed,auto_class,'rgb','os*',4)
hold on; plot(x,y)
xlabel('log pixel area');
ylabel('track speed (pixels/s)')
legend('insect','bat','bird')
