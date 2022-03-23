/* rewrote this from help file Tutorials > Mark_Polishook_tutorial 17_Delays_reverbs

This also uses the built in microphone as input

Please set volumes low when you run this */

(
s.freeAll;
ServerTree.removeAll;
s.newBusAllocators;
s.boot;
)

(


SynthDef.new(\sine, {
	arg freq=800, atk=0.001, rel=0.2, out=0, pan=0, amp=0.5, direct=0.5, effectBus, trigger=1, graindur=0.2;
	var sig, env;
	sig = SinOsc.ar(freq); ////(trigger, dur: graindur, freq: freq);
	env = EnvGen.kr(Env.perc(atk, rel), doneAction: 2);
	sig = sig * env * amp;
	sig = Pan2.ar(sig, pan);
	Out.ar(out, sig);
}).add;

SynthDef(\filtereddust, {
    var sig;
	sig = Mix.arFill(10, { Resonz.ar(in: Dust.ar(density: 0.1, mul: 100), freq: Rand(400, 800, 1600, 3200), bwr: 0.003)}); // Bandwidth ratio (reciprocal of Q). rq = bandwidth / centerFreq. The reciprocal of Q is used rather than Q because it saves a divide operation inside the unit generator.
	sig = sig *2;
	Out.ar(2, sig);
}).add;



SynthDef(\predelay, {
	var sig;
	sig = DelayN.ar(In.ar(2, 1), 0.048, 0.048);
	ReplaceOut.ar(4, sig);

}).add;

SynthDef(\combs,
	{
	var sig;
	sig = Mix.arFill(7, { CombL.ar(In.ar(4, 1), 0.1, LFNoise1.kr(Rand(0, 0.1), 0.04, 0.05), 15) });
	ReplaceOut.ar(6, sig);

}).add;

SynthDef(\allpass, {
	arg amp = 0.2;
	var source;
    source = In.ar(6, 1);
	4.do({ source = AllpassN.ar(source, 0.050, [Rand(0, 0.05), Rand(0, 0.05)], 1) });
	ReplaceOut.ar(8, source * amp);

}).add;

SynthDef(\mixer, {
	arg amp = 1;
	var sig;
	sig = Mix.ar([In.ar(2, 1), In.ar(8, 2)] * amp);
	ReplaceOut.ar(0, sig * amp);
}).add;
)

(
Synth.new(\sine);
Synth.tail(s, \filtereddust);
Synth.tail(s, \predelay);
Synth.tail(s, \combs);
Synth.tail(s, \allpass);
Synth.tail(s, \mixer);


~notes = [0,3,7, 12];
~freqs = Scale.minorPentatonic.degreeToFreq([-5,-4,-3,-2,-1,0,1,2,3,4,5, 10], 60.midicps,0);

)

(
~sineplayer = Pbindef.new(\sineplayer,
	\instrument, \sine,
	\dur, Pxrand([0.8, 1.6], inf),
	\freq, Pxrand(~freqs, inf),
	//\note, Pxrand([~notes+12,~notes,~notes-12].flat,inf),
	\pan, Pxrand([-1, -0.75, -0.5, 0, 0.5, 0.75, 1], inf), //-- doesn't work with this config
	\out, 2,
	\amp, 0.1,
	\atk, 0.01,
	\rel,  0.4, //Pxrand([0.4, 0.5, 0.6, 0.8, 1], inf),
	\graindur, Pxrand([0.01, 0.02, 0.04, 0.08], inf),
	//\filterfrxeq, Prand([300,1000, 2000], inf),
).play(quant:1);
)



