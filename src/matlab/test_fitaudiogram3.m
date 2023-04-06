freqs = 10 .^ linspace(log10(200.0), log10(20000.0), 100);
losses = linspace(0.0, 50.0, 100);

[cohc2, cihc2, ~] = fitaudiogram2(freqs, losses, 2);
[cohc3, cihc3] = fitaudiogram3(freqs, losses, 2);

figure;
hold on;
plot(freqs, cohc2);
plot(freqs, cohc3);
set(gca, 'xscale', 'log')
legend(["Original", "New"]);
hold off;