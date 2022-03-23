(
p = ServerOptions.new;
s.makeWindow;// for recording
p.memSize = 16000;


s.newBusAllocators;
s.freeAll;
Buffer.freeAll;

s.boot;
)


(
// order of operation
~sourceGrp = Group.new(s);
~fxGrp = Group.after(~sourceGrp);


// Audio Busses

~bus1 = Bus.audio(s,2);

// Synthdefs

SynthDef.new(\sine, {
	arg atk=0.01, rel=0.2, amp=0.2, freq=400, filterfreq=1200, pan=0, direct=0.5, out=0, effectBus;
	var sig, env;
	sig = SinOsc.ar(freq);
	env = EnvGen.kr(Env.perc(atk,rel), doneAction: 2);
	sig = sig * env;
	sig=MoogFF.ar(sig, filterfreq, gain: 2);
	sig=Pan2.ar(sig, pan);
	sig = sig * amp;
	Out.ar(out, sig * direct);// direct clean signal
    Out.ar(effectBus, sig * (1 - direct));
}).add;


SynthDef.new(\sine2, {
	arg atk=0.01, rel=0.2, amp=0.5, freq=400, filterfreq=1200, pan=0, direct=0.5, out=0, effectBus;
	var sig, env;
	sig=Array.fill(3,{arg i;
		sig = SinOscFB.ar(freq*(2**i));
	    }
	    );
	env = EnvGen.kr(Env.perc(atk,rel), doneAction: 2);
	sig = sig * env;
	sig=MoogFF.ar(sig, filterfreq, gain: 2);
	sig=Pan2.ar(sig, pan);
	sig = sig * amp;
	Out.ar(out, sig * direct);// direct clean signal
    Out.ar(effectBus, sig * (1 - direct));
}).add;


SynthDef.new(\sine3, {
	arg atk=0.01, rel=0.2, amp=0.5, freq=400, filterfreq=1200, pan=0, direct=0.5, out=0, effectBus;
	var sig, env;
	sig=Array.fill(3,{arg i;
		sig = SinOscFB.ar(freq*(2**i));
	    }
	    );
	env = EnvGen.kr(Env.perc(atk,rel), doneAction: 2);
	sig = sig * env;
	sig=MoogFF.ar(sig, filterfreq, gain: 2);
	sig=Pan2.ar(sig, pan);
	sig = sig * amp;
	Out.ar(out, sig * direct);// direct clean signal
    Out.ar(effectBus, sig * (1 - direct));
}).add;


SynthDef.new(\drone, {
	arg amp=0.1, freq=65.4, atk=1, rel=2, ctrlfreq=0.02,
	filterfreq=400, filterctrlfreq=0.01, gate=1, out=0, center=0;
	var sig, env;
	freq=freq;//modulation attempt
	sig=Array.fill(3,{arg i;
		var sig2;
		var freq2=freq*(2**i)+SinOsc.kr(ctrlfreq,mul: 2);// i is the exponent of 2, so first array is frequency times 2, second frequency times 4, and 3rd, frequency times 8 ... clever way to create multiple frequencies / octaves
		sig2=SinOsc.ar(freq:freq2,mul:1/(2**i));
	});
	env = EnvGen.kr(Env.asr(2, 2, 2, curve: 3), gate, doneAction: 0);
	sig = sig*env*amp;
	sig=Mix.ar(sig);// mixer
	sig=Splay.ar(sig, center: center);//spread on stereo field
	sig=LPF.ar(sig,freq: filterfreq+SinOsc.kr(filterctrlfreq,mul:300));
	Out.ar(out, sig);
}	).add;


SynthDef.new(\reverb, {
	arg freq=440, in, out=0;
	var sig;
	sig=In.ar(in, 2);
	sig=JPverb.ar(sig,t60: 1, damp: 0.3, size: 2);
	Out.ar(out,sig);
}).add;


a = Synth.new(\sine, [\out,0, \effectBus, ~bus1], target: ~sourceGrp);
b = Synth.new(\sine2, [\out,0, \effectBus, ~bus1], target: ~sourceGrp);
c = Synth.new(\sine3, [\out,0, \effectBus, ~bus1], target: ~sourceGrp);
d = Synth.new(\reverb,[\in,~bus1, \out,0], ~fxGrp);
//d = Synth.new(\drone, [\out,0, \effectBus, ~bus1], target: ~sourceGrp);
)


// MIDI via T-1 or GRID or other MIDI devices!!

MIDIIn.connectAll; // connect all midi devices


MIDIFunc.trace(true); // Quick way to see all incoming MIDI devices to SC messages

MIDIFunc.trace(false); // stop it

// play the Synths with Midi device

(
MIDIdef.noteOn(\someKeyboard, { arg vel, note;
Synth(\sine, [\freq, note.midicps, \amp, vel.linlin(0, 127, 0, 1), \out,0, \effectBus, ~bus1], target: ~sourceGrp);
	Synth(\sine2, [\freq, note.midicps, \amp, vel.linlin(0, 127, 0, 1), \out,0, \effectBus, ~bus1], target: ~sourceGrp);
	Synth(\sine3, [\freq, note.midicps, \amp, vel.linlin(0, 127, 0, 1), \out,0, \effectBus, ~bus1], target: ~sourceGrp);
});
)


// or play the Synths with patterns, those can be re-evaluated, so you can live code with those

(
// Pattern

n = [0,3,7,12];

o = Array.fill(10, Pxrand([n], inf).iter); // create chords

~sineplayer = Pbindef.new(\sineplayer,
	\instrument, \sine,
	//\Scale, Scale.minor, // scale only works with /degree!
	\ctranspose,[24],
	\note, Prand(n, inf),
	\dur, 0.1,
	\pan, Pwhite(-1, 1, inf),
	\direct, 0.5, // direct signal 1 = dry, 0 = wet
	\out, 0,
	\amp, 0.3,
	\effectBus, ~bus1,
	\filterfrxeq, Prand([300,1000, 2000], inf),
).play(quant:1);

~sineplayer2 = Pbindef.new(\sineplayer2,
	\instrument, \sine2,
	//\Scale, Scale.minor, // scale only works with /degree!
	\ctranspose,[0],
	\note, Prand(n, inf),
	\dur, 0.2,
	\pan, Pwhite(-1, 1, inf),
	\direct, 0.5, // direct signal 1 = dry, 0 = wet
	\out, 0,
	\amp, 0.2,
	\effectBus, ~bus1,
	\filterfrxeq, Prand([300,1000, 2000], inf),
).play(quant:1);


~sineplayer3 = Pbindef.new(\sineplayer3,
	\instrument, \sine3,
	//\Scale, Scale.minor, // scale only works with /degree!
	\ctranspose,[-12],
	\note, Pshuf(n, inf),
	\dur, 0.8,
	\pan, Pwhite(-1, 1, inf),
	\direct, 0.8, // direct signal 1 = dry, 0 = wet
	\out, 0,
	\atk, 0.1,
	\rel, 0.2,
	\amp, 0.2,
	\effectBus, ~bus1,
	\filterfreq, Prand([300,1000, 2000], inf),
).play(quant:1);


e = Synth.new(\drone, [\out,0, \gate, 1, \amp,0.1]);



)

// stop the three players individually

~sineplayer.stop;
~sineplayer2.stop;
~sineplayer3.stop;

// set arguments to the drone

e.set(\gate,0); // turn drone off
e.set(\ctrlfreq,0.02); // control controlfrequency



	